/*
    Copyright 2008 Torsten Curdt, http://vafer.org

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

    http://www.gnu.org/licenses/gpl.txt
*/

#import "MyDocument.h"
#import "uif.h"

@implementation MyDocument

+ (void) load
{
    endian = 1;

    if(*(char *)&endian) {
        endian = 0;
    } 
}

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    
    [SizeField setStringValue:@""];
    [VersionField setStringValue:@""];
    [ImageTypeField setStringValue:@""];
    [SectorsField setStringValue:@""];
    [SectorSizeField setStringValue:@""];
    [HashField setStringValue:@""];
    [StatusField setStringValue:@""];

    [NSThread detachNewThreadSelector:@selector(convert:)
                             toTarget:self
                           withObject:nil];
}

#define SHOW(...) NSLog(__VA_ARGS__); [StatusField performSelectorOnMainThread: @selector(setStringValue:) withObject:@"Failed" waitUntilDone: FALSE];

- (void) convertWithZlib:(z_stream*)z
{
    NSString *sourceName = [self fileName];
    NSString *targetName = [[sourceName stringByDeletingPathExtension] stringByAppendingPathExtension:@"iso"];
    
    NSLog(@"Converting from %@ to %@", sourceName, targetName);

    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:sourceName]) {
        NSRunCriticalAlertPanel(@"Source not found", [NSString stringWithFormat:@"Cannot find the file to open.\n'%@'", sourceName], @"Bummer", nil, nil);

        SHOW(@"Source not found");
        return;
    }

    if ([fileManager fileExistsAtPath:targetName]) {
        if(NSRunCriticalAlertPanel(@"Target already exists", [NSString stringWithFormat:@"Do you want me to overwrite existing file?\n'%@'", targetName], @"Overwrite", @"Cancel", nil) != 1) {

            SHOW(@"Target exists. Canceled");
            return;
        }
        if (![fileManager isWritableFileAtPath:targetName]) {
            NSRunCriticalAlertPanel(@"Target not writeable", [NSString stringWithFormat:@"Cannot overwrite the existing file.\n'%@'", targetName], @"Bummer", nil, nil);

            SHOW(@"Target not writeable");
            return;
        }
    }


    FILE *fdi = fopen([sourceName UTF8String], "rb");

    if (fdi == NULL) {
        SHOW(@"Failed to open source %@", sourceName);
        return;
    }

    if(fseek(fdi, 0, SEEK_END) != 0) {
        SHOW(@"Failed to seek");
        fclose(fdi);
        return;
    }

    u64 file_size = ftell(fdi);

    if(fseek(fdi, file_size - sizeof(bbis_t), SEEK_SET) != 0) {
        SHOW(@"Failed to seek");
        fclose(fdi);
        return;
    }

    bbis_t bbis;

    if (myread(fdi, &bbis, sizeof(bbis_t)) != 0) {
        SHOW(@"Failed to read");
        fclose(fdi);
        return;
    }

    b2l_bbis(&bbis);

    if(bbis.sign != BBIS_SIGN) {
        NSRunCriticalAlertPanel(@"Wrong signature", [NSString stringWithFormat:@"Cannot convert - not a UIF file.\n'%@'", targetName], @"Bummer", nil, nil);
        SHOW(@"Wrong signature");        
        fclose(fdi);
        return;
    }
    
    if(fseek(fdi, bbis.blhr, SEEK_SET) != 0) {
        SHOW(@"Failed to seek");
        fclose(fdi);
        return;
    }

    blhr_t blhr;

    if (myread(fdi, &blhr, sizeof(blhr_t)) != 0) {
        SHOW(@"Failed to read");

        fclose(fdi);
        return;
    }
    
    b2l_blhr(&blhr);

    if(blhr.sign != BLHR_SIGN) {
        if(blhr.sign == BSDR_SIGN) {
            NSRunCriticalAlertPanel(@"Password protected", [NSString stringWithFormat:@"Cannot convert - file is password protected.\n'%@'", targetName], @"Bummer", nil, nil);
            SHOW(@"Password protected");
            fclose(fdi);
            return;
        } else {
            NSRunCriticalAlertPanel(@"Wrong signature", [NSString stringWithFormat:@"Cannot convert - not a UIF file.\n'%@'", targetName], @"Bummer", nil, nil);
            SHOW(@"Wrong signature");
            fclose(fdi);
            return;
        }
    }

    [SizeField performSelectorOnMainThread: @selector(setStringValue:) withObject: [NSString stringWithFormat:@"%d", file_size] waitUntilDone: FALSE];
    [VersionField performSelectorOnMainThread: @selector(setStringValue:) withObject: [NSString stringWithFormat:@"%d", bbis.ver] waitUntilDone: FALSE];
    [ImageTypeField performSelectorOnMainThread: @selector(setStringValue:) withObject: [NSString stringWithFormat:@"%d", bbis.image_type] waitUntilDone: FALSE];
    [SectorsField performSelectorOnMainThread: @selector(setStringValue:) withObject: [NSString stringWithFormat:@"%d", bbis.sectors] waitUntilDone: FALSE];
    [SectorSizeField performSelectorOnMainThread: @selector(setStringValue:) withObject: [NSString stringWithFormat:@"%d", bbis.sectorsz] waitUntilDone: FALSE];
    [HashField performSelectorOnMainThread: @selector(setStringValue:) withObject: [NSString stringWithFormat:@"%s", show_hash(bbis.hash)] waitUntilDone: FALSE];

#ifndef DEBUG
    if (bbis.ver > 1) {
        NSRunCriticalAlertPanel(@"Wrong version", [NSString stringWithFormat:@"Cannot convert - this version %d of the UIF format is not yet supported.", bbis.ver], @"Bummer", nil, nil);
        SHOW(@"Version %d is not yet supported", bbis.ver);
        fclose(fdi);
        return;
    }
#endif

    long blhr_data_z_len = blhr.size - 8;
    void *blhr_data_z = malloc(blhr_data_z_len);
    if (!blhr_data_z) {
        SHOW(@"Failed to allocate memory for compressed data header");
        fclose(fdi);
        return;
    }
    
    if (myread(fdi, blhr_data_z, blhr_data_z_len) != 0) {
        SHOW(@"Failed to read compressed data header");
        free(blhr_data_z);
        fclose(fdi);
        return;
    }

    long blhr_data_len = sizeof(blhr_data_t) * blhr.num;
    blhr_data_t *blhr_data = malloc(blhr_data_len);
    if(!blhr_data) {
        SHOW(@"Failed to allocate memory for uncompressed data header");
        free(blhr_data_z);
        fclose(fdi);
        return;
    }

    NSLog(@"Uncompressing data header %d -> %d", blhr_data_z_len, blhr_data_len);

/*
    FILE *fd = fopen([[targetName stringByAppendingString:@"-header"] UTF8String], "wb");
    fwrite(blhr_data_z, 1, blhr_data_z_len, fd);
    fclose(fd);
*/
    if (unzip(z, blhr_data_z, blhr_data_z_len, (void *)blhr_data, blhr_data_len) == -1) {
        SHOW(@"Failed to uncompress data header: %s", z->msg);
        free(blhr_data);
        free(blhr_data_z);
        fclose(fdi);
        return;
    }
    
    free(blhr_data_z);
    
    
    FILE *fdo = fopen([targetName UTF8String], "wb");

    if (fdo == NULL) {
        SHOW(@"Failed to open target %@", targetName);
        free(blhr_data);
        fclose(fdi);
        return;
    }

    [ProgressIndicator setMaxValue:blhr.num-1];
    [ProgressIndicator startAnimation:self];
    [StatusField performSelectorOnMainThread: @selector(setStringValue:) withObject: @"Converting..." waitUntilDone: FALSE];

    int i;
    for(i = 0; i < blhr.num; i++) {

        NSLog(@"blhr %d", i);

        [ProgressIndicator setDoubleValue:(double)i];
        [ProgressIndicator displayIfNeeded];

        b2l_blhr_data(&blhr_data[i]);

        long data_z_len = blhr_data[i].zsize;
        void *data_z = malloc(data_z_len);
        
        if (!data_z) {
            [ProgressIndicator stopAnimation:self];
            SHOW(@"Failed to allocate memory for compressed data");        
            free(blhr_data);
            fclose(fdi);
            fclose(fdo);
            return;
        }

        if(blhr_data[i].zsize) {
            if(fseek(fdi, blhr_data[i].offset, SEEK_SET) != 0) {
                [ProgressIndicator stopAnimation:self];
                SHOW(@"Failed to seek to data");
                free(data_z);
                free(blhr_data);
                fclose(fdi);
                fclose(fdo);
                return;
            }
            
            if (myread(fdi, data_z, blhr_data[i].zsize) != 0) {
                [ProgressIndicator stopAnimation:self];
                SHOW(@"Failed to read data");
                free(data_z);
                free(blhr_data);
                fclose(fdi);
                fclose(fdo);
                return;
            }
        }

        blhr_data[i].size *= bbis.sectorsz;

        long data_len = blhr_data[i].size;
        void *data = malloc(data_len);
        if (!data) {
            [ProgressIndicator stopAnimation:self];
            SHOW(@"Failed to allocate memory for uncompressed data");
            free(data_z);
            free(blhr_data);
            fclose(fdi);
            fclose(fdo);
            return;
        }

        switch(blhr_data[i].type) {
            case 1: {   // non compressed
                NSLog(@"Uncompressed");
                if(data_z_len > data_len) {
                    [ProgressIndicator stopAnimation:self];
                    SHOW(@"Input is bigger than output");
                    free(data);
                    free(data_z);
                    free(blhr_data);
                    fclose(fdi);
                    fclose(fdo);
                    return;
                }
                memcpy(data, data_z, data_z_len);
                memset(data + data_z_len, 0, data_len - data_z_len); // needed?
                break;
            }
            case 3: {   // multi byte
                NSLog(@"Multi byte");
                memset(data, 0, data_len);
                break;
            }
            case 5: {   // compressed
                NSLog(@"Compressed");
                if (unzip(z, data_z, data_z_len, data, data_len) == -1) {
                    [ProgressIndicator stopAnimation:self];
                    SHOW(@"Failed to uncompress data");
                    free(data);
                    free(data_z);
                    free(blhr_data);
                    fclose(fdi);
                    fclose(fdo);
                    return;
                }
                break;
            }
            default: {
                [ProgressIndicator stopAnimation:self];
                SHOW(@"Unknown type (%d)", blhr_data[i].type);
                free(data);
                free(data_z);
                free(blhr_data);
                fclose(fdi);
                fclose(fdo);
                return;
            }
        }

        if(fseek(fdo, blhr_data[i].sector * bbis.sectorsz, SEEK_SET) != 0) {
            [ProgressIndicator stopAnimation:self];
            SHOW(@"Failed to seek to output");            
            free(data);
            free(data_z);
            free(blhr_data);
            fclose(fdi);
            fclose(fdo);
            return;
        }
        
        mywrite(fdo, data, data_len);
        
        //tot += blhr_data[i].size;
        
        free(data);
        free(data_z);
    }


    [ProgressIndicator stopAnimation:self];
    [StatusField performSelectorOnMainThread: @selector(setStringValue:) withObject: @"Finished successfully" waitUntilDone: FALSE];
    free(blhr_data);
    fclose(fdi);
    fclose(fdo);
    return;

}


/*
int BZ2_bzBuffToBuffDecompress( char*         dest,
                                unsigned int* destLen,
                                char*         source,
                                unsigned int  sourceLen,
                                int           small,
                                int           verbosity );
                                */
- (void)convert:(id)sender
{
    z_stream z;

    z.zalloc = (alloc_func)0;
    z.zfree  = (free_func)0;
    z.opaque = (voidpf)0;

    if(inflateInit2(&z, 15)) {
        NSLog(@"Failed to open zlib");
        return;
    }

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    [self convertWithZlib:&z];
    
    [pool release];
    
    inflateEnd(&z);
    
    //[[NSApplication sharedApplication] requestUserAttention:NSInformationalRequest];
    [NSApp requestUserAttention:NSInformationalRequest];
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
    [self setFileName:fileName];
    return YES;
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    return nil;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{    
    return YES;
}

@end

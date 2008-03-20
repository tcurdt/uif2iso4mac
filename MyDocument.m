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

- (void)convert:(id)inObject
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSString *sourceName = [self fileName];
    NSString *targetName = [[sourceName stringByDeletingPathExtension] stringByAppendingPathExtension:@"iso"];

    NSLog(@"Converting from %@ to %@", sourceName, targetName);

    z_stream    z;
    blhr_data_t *blhr_data;
    blhr_t      blhr;
    bbis_t      bbis;
    FILE    *fdi,
            *fdo;
    u64     tot,
            file_size;
    int     i;
    unsigned insz,
            outsz;
    u8      *in,
            *out;

    endian = 1;
    if(*(char *)&endian) endian = 0;


    [StatusField performSelectorOnMainThread: @selector(setStringValue:) withObject: @"Opening source" waitUntilDone: FALSE];

    fdi = fopen([sourceName cString], "rb");
    if(!fdi) {
        [StatusField performSelectorOnMainThread: @selector(setStringValue:) withObject: @"Failed to open source" waitUntilDone: FALSE];
        return;
    }


    [StatusField performSelectorOnMainThread: @selector(setStringValue:) withObject: @"Opening target" waitUntilDone: FALSE];

    fdo = fopen([targetName cString], "rb");
    if(fdo) {
        fclose(fdo);
        if(NSRunCriticalAlertPanel(@"Target already exists", @"Do you want me to overwrite exising file?", @"Overwrite", @"Cancel", nil) != 1) {
            [StatusField performSelectorOnMainThread: @selector(setStringValue:) withObject: @"Target already exists" waitUntilDone: FALSE];
            return;
        }
    }

    fdo = fopen([targetName cString], "wb");
    if(!fdo) {
        [StatusField performSelectorOnMainThread: @selector(setStringValue:) withObject: @"Failed to open target" waitUntilDone: FALSE];
        return;
    }

    z.zalloc = (alloc_func)0;
    z.zfree  = (free_func)0;
    z.opaque = (voidpf)0;
    if(inflateInit2(&z, 15)) {
        [StatusField performSelectorOnMainThread: @selector(setStringValue:) withObject: @"Failed to open zlib library" waitUntilDone: FALSE];
        return;
    }

    fseek(fdi, 0, SEEK_END);
    file_size = ftell(fdi);
    if(fseek(fdi, file_size - sizeof(bbis), SEEK_SET)) {
        [StatusField performSelectorOnMainThread: @selector(setStringValue:) withObject: @"Failed to seek" waitUntilDone: FALSE];
        return;
    }

    myfr(fdi, &bbis, sizeof(bbis));
    b2l_bbis(&bbis);
    if(bbis.sign != BBIS_SIGN) {
        [StatusField performSelectorOnMainThread: @selector(setStringValue:) withObject: @"Wrong signature" waitUntilDone: FALSE];
        return;
    }

    [SizeField performSelectorOnMainThread: @selector(setStringValue:) withObject: [NSString stringWithFormat:@"%d", file_size] waitUntilDone: FALSE];
    [VersionField performSelectorOnMainThread: @selector(setStringValue:) withObject: [NSString stringWithFormat:@"%d", bbis.ver] waitUntilDone: FALSE];
    [ImageTypeField performSelectorOnMainThread: @selector(setStringValue:) withObject: [NSString stringWithFormat:@"%d", bbis.image_type] waitUntilDone: FALSE];
    [SectorsField performSelectorOnMainThread: @selector(setStringValue:) withObject: [NSString stringWithFormat:@"%d", bbis.sectors] waitUntilDone: FALSE];
    [SectorSizeField performSelectorOnMainThread: @selector(setStringValue:) withObject: [NSString stringWithFormat:@"%d", bbis.sectorsz] waitUntilDone: FALSE];
    [HashField performSelectorOnMainThread: @selector(setStringValue:) withObject: [NSString stringWithFormat:@"%s", show_hash(bbis.hash)] waitUntilDone: FALSE];

    if(fseek(fdi, bbis.blhr, SEEK_SET)) {
        [StatusField performSelectorOnMainThread: @selector(setStringValue:) withObject: @"Failed to seek" waitUntilDone: FALSE];
        return;
    }

    myfr(fdi, &blhr, sizeof(blhr));
    b2l_blhr(&blhr);
    if(blhr.sign != BLHR_SIGN) {
        if(blhr.sign == BSDR_SIGN) {
            [StatusField performSelectorOnMainThread: @selector(setStringValue:) withObject: @"Password protected" waitUntilDone: FALSE];
            return;
        } else {
            [StatusField performSelectorOnMainThread: @selector(setStringValue:) withObject: @"Wrong signature" waitUntilDone: FALSE];
            return;
        }
    }

    in   = out   = NULL;
    insz = outsz = 0;
    tot  = 0;

    myalloc(&in, blhr.size - 8, &insz);
    myfr(fdi, in, insz);

    blhr_data = (void *)malloc(sizeof(blhr_data_t) * blhr.num);
    if(!blhr_data) {
    }

    unzip(&z, in, insz, (void *)blhr_data, sizeof(blhr_data_t) * blhr.num);

    [ProgressIndicator setMaxValue:blhr.num-1];
    [ProgressIndicator startAnimation:self];
    [StatusField performSelectorOnMainThread: @selector(setStringValue:) withObject: @"Converting..." waitUntilDone: FALSE];

    for(i = 0; i < blhr.num; i++) {

        NSLog(@"blhr %d", i);
        //[ProgressIndicator performSelectorOnMainThread: @selector(setDoubleValue:) withObject: waitUntilDone: FALSE];
        [ProgressIndicator setDoubleValue:(double)i];
        [ProgressIndicator displayIfNeeded];

        b2l_blhr_data(&blhr_data[i]);

        myalloc(&in, blhr_data[i].zsize, &insz);

        if(blhr_data[i].zsize) {
            if(fseek(fdi, blhr_data[i].offset, SEEK_SET)) {
            }
            myfr(fdi, in, blhr_data[i].zsize);
        }

        blhr_data[i].size *= bbis.sectorsz;
        myalloc(&out, blhr_data[i].size, &outsz);

        switch(blhr_data[i].type) {
            case 1: {   // non compressed
                if(blhr_data[i].zsize > blhr_data[i].size) {
//                    printf("\nError: input size is bigger than output\n");
//                    myexit();
                }
                memcpy(out, in, blhr_data[i].zsize);
                memset(out + blhr_data[i].zsize, 0, blhr_data[i].size - blhr_data[i].zsize); // needed?
                break;
            }
            case 3: {   // multi byte
                memset(out, 0, blhr_data[i].size);
                break;
            }
            case 5: {   // compressed
                unzip(&z, in, blhr_data[i].zsize, out, blhr_data[i].size);
                break;
            }
            default: {
//                printf("\nError: unknown type (%d)\n", blhr_data[i].type);
//                myexit();
            }
        }

        if(fseek(fdo, blhr_data[i].sector * bbis.sectorsz, SEEK_SET)) {
        }
        myfw(fdo, out, blhr_data[i].size);
        tot += blhr_data[i].size;
    }

    inflateEnd(&z);
    fclose(fdi);
    fclose(fdo);

    [ProgressIndicator stopAnimation:self];
    [StatusField performSelectorOnMainThread: @selector(setStringValue:) withObject: @"Finished successfully" waitUntilDone: FALSE];

    [pool release];

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

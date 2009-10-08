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
#import "NSProgressIndicator+Thread.h"
#import "TaskCommand.h"

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self) {
        NSString *executable = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"uif2iso"];
        
        NSLog(@"Using executable %@", executable);
        
        cmd = [[TaskCommand alloc] initWithPath:executable];
        
        terminationReason = END_NORMAL;
        done = NO;
    }
    return self;
}

- (NSString *)windowNibName
{
    return NSLocalizedString(@"MyDocument", nil);
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    
    [sizeField setStringValue:@""];
    [versionField setStringValue:@""];
    [imageTypeField setStringValue:@""];
    [hashField setStringValue:@""];
    [statusField setStringValue:@""];

    [progressIndicator setDoubleValue:0.0];

}

- (void) showWindows
{

    NSString *sourceName = [self fileName];

//    NSOpenPanel *targetDialog = [NSOpenPanel openPanel];
//    [targetDialog setCanChooseFiles:YES];
//    [targetDialog setCanChooseDirectories:YES];
//
//    if ([targetDialog runModalForDirectory:[sourceName stringByDeletingLastPathComponent] file:sourceName] != NSOKButton) {
//        return;
//    }
//    NSArray *files = [targetDialog filenames];
//    int i;
//    for(i = 0; i < [files count]; i++ ) {
//        NSString *fileName = [files objectAtIndex:i];
//        NSLog(@"selected = %@", fileName);
//    }

    targetName = [[sourceName stringByDeletingPathExtension] stringByAppendingPathExtension:@"iso"];
    
    NSLog(@"Converting from %@ to %@", sourceName, targetName);
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:sourceName]) {
    
        NSRunCriticalAlertPanel(
            NSLocalizedString(@"Source not found", nil),
            [NSString stringWithFormat:NSLocalizedString(@"Cannot find the file to open.\n'%@'", nil), sourceName],
            NSLocalizedString(@"Bummer", nil),
            nil, nil);

        NSLog(@"Source not found");
        [self close];
        return;
    }

    if ([fileManager fileExistsAtPath:targetName]) {
        if(NSRunCriticalAlertPanel(
            NSLocalizedString(@"Target already exists", nil),
            [NSString stringWithFormat:NSLocalizedString(@"Do you want me to overwrite existing file?\n'%@'", nil), targetName],
            NSLocalizedString(@"Overwrite", nil),
            NSLocalizedString(@"Cancel", nil),
            nil) != 1) {

            NSLog(@"Target exists. Canceled");
            [self close];
            return;
        }
        if (![fileManager isWritableFileAtPath:targetName]) {

            NSRunCriticalAlertPanel(
                NSLocalizedString(@"Target not writeable", nil),
                [NSString stringWithFormat:NSLocalizedString(@"Cannot overwrite the existing file.\n'%@'", nil), targetName],
                NSLocalizedString(@"Bummer", nil),
                nil, nil);

            NSLog(@"Target not writeable");
            [self close];
            return;
        }
        
        [fileManager removeFileAtPath:targetName handler:nil];
    }

    NSString *dir = [targetName stringByDeletingLastPathComponent];
    if (![fileManager isWritableFileAtPath:dir]) {

        NSRunCriticalAlertPanel(
            NSLocalizedString(@"Target not writeable", nil),
            [NSString stringWithFormat:NSLocalizedString(@"Cannot write to directory.\n'%@'", nil), dir],
            NSLocalizedString(@"Bummer", nil),
            nil, nil);

        NSLog(@"Target directory not writeable");
        [self close];
        return;
    }

    [super showWindows];

    NSLog(@"Converting %@ -> %@", sourceName, targetName);
    
    [cmd setArgs:[NSArray arrayWithObjects:
                        sourceName,
                        targetName,
                        nil]];
    [cmd setDelegate:self];
    [cmd execute];
}

- (IBAction) abort:(id)sender
{
    if (!done) {
        [abortButton setEnabled:NO];
        
        terminationReason = END_ABORTED;

        NSLog(@"aborting");
        [cmd abort];
    } else {
        [self close];
    }
}

- (NSString*) convertError:(NSString*)s
{
        /*
        Error: wrong bbis signature (%08x)
        Error: wrong blhr signature (%08x)
        Error: zlib initialization error
        Error: input size is bigger than output
        Error: unknown type (%d)
        Error: the truncated file is smaller than how much I requested
        Error: incomplete input file, can't read %u bytes
        Error: problems during the writing of the output file
        Error: the input lzma block is too short (%u)
        Error: the compressed LZMA input is wrong or incomplete (%d)
        Error: the compressed input is wrong or incomplete        
        Error: the magiciso_is_shit encryption can't work on your system
        Error: this executable has been compiled without support for magiciso_is_shit
        */

        NSArray *errorPrefixes = [NSArray arrayWithObjects:
            @"Error: wrong bbis signature",
            @"Error: wrong blhr signature",
            @"Error: zlib initialization error",
            @"Error: input size is bigger than output",
            @"Error: unknown type",
            @"Error: the truncated file is smaller than how much I requested",
            @"Error: incomplete input file",
            @"Error: problems during the writing of the output file",
            @"Error: the input lzma block is too short",
            @"Error: the compressed LZMA input is wrong or incomplete",
            @"Error: the compressed input is wrong or incomplete",
            @"Error: the magiciso_is_shit encryption can't work on your system",
            @"Error: this executable has been compiled without support for magiciso_is_shit",
            nil
        ];
        
        int count = [errorPrefixes count];
        while(count--) {
            NSString *errorPrefix = [errorPrefixes objectAtIndex:count];
            if ([s hasPrefix:errorPrefix]) {
                return NSLocalizedString(errorPrefix, nil);
            }
        }

        return NSLocalizedString(@"unknown error", nil);
}

- (BOOL) scan: (NSString*)s  hexLongLong:(unsigned long long*)result
{
    unsigned long long r = 0;
    
    const char* chars = [[s uppercaseString] cStringUsingEncoding:NSASCIIStringEncoding];
    
    for(;;) {
        char c = *chars++;
        
        if (c == 0) break;
        
        unsigned int value;
        
        if (c >= '0' && c <= '9') {
            value = c - '0';
        } else if (c >= 'A' && c <= 'F') {
            value = c - 'A' + 10;
        } else {
            return NO;
        }
        
        r = (r << 4) + value;
    }
    
    *result = r;
    return YES;
}

- (void) receivedOutput:(NSString*)s
{
    if ([s hasSuffix:@"%\r"]) {
        NSString *sub = [s substringWithRange:NSMakeRange(2,3)];        
        double p = [sub doubleValue];
        [progressIndicator setDoubleValue:p];
    } else if ([@"- start unpacking:" isEqualToString:s]) {
        [progressIndicator startAnimation:self];
        [progressIndicator setMaxValue:100];

        // TODO calculate size and resize the window
        [statusField setStringValue:NSLocalizedString(@"Converting...", nil)];
    } else if ([@"- finished" isEqualToString:s]) {
        [progressIndicator setDoubleValue:100];
    } else if ([s hasPrefix:@"  file size"]) {
        NSString *sub = [s substringFromIndex:15];

        unsigned long long size;
        if([self scan: sub hexLongLong: &size]) {
            [sizeField setStringValue:[NSString stringWithFormat:@"%lu", size]];
        } else {
            NSLog(@"Could not parse size: %@");
        }

    } else if ([s hasPrefix:@"  version"]) {
        NSString *sub = [s substringFromIndex:15];
        [versionField setStringValue:sub];
    } else if ([s hasPrefix:@"  image type"]) {
        NSString *sub = [s substringFromIndex:15];
        [imageTypeField setStringValue:sub];
    } else if ([s hasPrefix:@"  hash"]) {
        NSString *sub = [s substringFromIndex:15];
        [hashField setStringValue:sub];
    } else if ([s hasPrefix:@"Error: "]) {       
        NSLog(@"OUT: [%@]", s);

        // TODO calculate size and resize the window
        [statusField setStringValue:[self convertError:s]];

        terminationReason = END_ERROR;
        
    } else {
        NSLog(@"OUT: [%@]", s);
    }
}

- (void) receivedError:(NSString*)s
{
    NSLog(@"ERR: %@", s);
}

- (NSString*) readInput
{
    return nil;
}

- (void) terminated
{
    [progressIndicator stopAnimation:self];

    [abortButton setTitle:NSLocalizedString(@"Done", nil)];
    [abortButton setEnabled:YES];

    switch (terminationReason) {
        case END_NORMAL:
            // TODO calculate size and resize the window
            [statusField setStringValue:NSLocalizedString(@"Finished successfully", nil)];
            break;
        case END_ABORTED:
            // TODO calculate size and resize the window
            [statusField setStringValue:NSLocalizedString(@"Aborted", nil)];        

            NSFileManager *fileManager = [NSFileManager defaultManager];

            if ([fileManager fileExistsAtPath:targetName]) {
                NSLog(@"removing incomplete file %@", targetName);
                [fileManager removeFileAtPath:targetName handler:nil];
            }
            break;
        case END_ERROR:
            break;
    }
    
    done = YES;
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

- (void) dealloc
{
    [cmd release];
    
    [super dealloc];
}



/*

UIF2ISO 0.1.6
by Luigi Auriemma
e-mail: aluigi@autistici.org
web:    aluigi.org

- open /Users/tcurdt/Desktop/uif2iso/Test.uif

  file size    0000000007af24e3
  version      4
  image type   8
  padding      0
  sectors      92602
  sectors size 2048
  blhr offset  0000000007af10d7
  blhr size    5132
  hash         d90c7cb1a9a418ba0d6f1576d31afe2c
  others       00000040 00000000 01 02 02 00 00000000

- enable magiciso_is_shit encryption
- ISO output image format
- create /Users/tcurdt/Desktop/uif2iso/Test.iso
- start unpacking:
  000%
  100%
- finished

*/

@end

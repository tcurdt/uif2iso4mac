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
    
    [SizeField setStringValue:@""];
    [VersionField setStringValue:@""];
    [ImageTypeField setStringValue:@""];
    [HashField setStringValue:@""];
    [StatusField setStringValue:@""];

    [ProgressIndicator setDoubleValue:0.0];

    NSString *sourceName = [self fileName];
    NSString *targetName = [[sourceName stringByDeletingPathExtension] stringByAppendingPathExtension:@"iso"];
    
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

    NSLog(@"Converting %@ -> %@", sourceName, targetName);
    
    [cmd setArgs:[NSArray arrayWithObjects:
                        sourceName,
                        targetName,
                        nil]];
    [cmd setDelegate:self];
    [cmd execute];
}

- (void) receivedOutput:(NSString*)s
{
    if ([s hasSuffix:@"%\r"]) {
        NSString *sub = [s substringWithRange:NSMakeRange(2,3)];        
        double p = [sub doubleValue];
        [ProgressIndicator setDoubleValue:p];
    } else if ([@"- start unpacking:" isEqualToString:s]) {
        [ProgressIndicator startAnimation:self];
        [ProgressIndicator setMaxValue:100];
        [StatusField setStringValue:NSLocalizedString(@"Converting...", nil)];
    } else if ([@"- finished" isEqualToString:s]) {
        [ProgressIndicator setDoubleValue:100];
        [ProgressIndicator stopAnimation:self];
        [StatusField setStringValue:NSLocalizedString(@"Finished successfully", nil)];
    } else if ([s hasPrefix:@"  file size"]) {
        NSString *sub = [s substringFromIndex:15];

        unsigned size;
        if([[NSScanner scannerWithString:sub] scanHexInt: &size]) {
            [SizeField setIntValue:size];
        } else {
            NSLog(@"Could not parse size: %@");
        }

    } else if ([s hasPrefix:@"  version"]) {
        NSString *sub = [s substringFromIndex:15];
        [VersionField setStringValue:sub];
    } else if ([s hasPrefix:@"  image type"]) {
        NSString *sub = [s substringFromIndex:15];
        [ImageTypeField setStringValue:sub];
    } else if ([s hasPrefix:@"  hash"]) {
        NSString *sub = [s substringFromIndex:15];
        [HashField setStringValue:sub];
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

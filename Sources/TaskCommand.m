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

#import "TaskCommand.h"


@implementation TaskCommand

- (id) initWithPath:(NSString*)pPath
{
    self = [super init];
    if (self != nil) {
    	task = [[NSTask alloc] init];

        args = nil;
        path = [pPath retain];
        
        outputBuffer = [[NSMutableString alloc] init];
        errorBuffer = [[NSMutableString alloc] init];

        terminated = NO;
    }
    
    return self;
}

- (void) setArgs:(NSArray*)pArgs
{
    [pArgs retain];
    [args release];
    args = pArgs;
}


- (id <TaskCommandDelegate>) delegate
{
    return delegate;
}

- (void) setDelegate:(id<TaskCommandDelegate>)pDelegate
{
    [pDelegate retain];   
    [delegate release];
    delegate = pDelegate;
}

- (void) receiveDataFrom:(NSFileHandle*)fileHandle to:(NSMutableString*)buffer with:(SEL)selector
{
    NSData *data = [fileHandle availableData];

    if ([data length]) {
        NSString *s = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding];
    
        [buffer appendString:s];
        
        NSArray *lines = [buffer componentsSeparatedByString:@"\n"];
        int lineCount = [lines count];
        int totalLength = 0;
        int i;

        for(i=0; i<lineCount; i++) {
            NSString *line = [lines objectAtIndex:i];

            [delegate performSelector:selector withObject:line];
            
            totalLength += [line length] + 1;
        }
    
        [buffer deleteCharactersInRange:NSMakeRange(0, totalLength-1)];

        [s release];
    }

    [fileHandle waitForDataInBackgroundAndNotify];
}

-(void) outData: (NSNotification *) notification
{
    NSFileHandle *fileHandle = (NSFileHandle*) [notification object];
    
    [self receiveDataFrom:fileHandle to:outputBuffer with:@selector(receivedOutput:)];
}

-(void) errData: (NSNotification *) notification
{
    NSFileHandle *fileHandle = (NSFileHandle*) [notification object];

    [self receiveDataFrom:fileHandle to:errorBuffer with:@selector(receivedError:)];
}


- (void) terminated: (NSNotification *)notification
{
    NSLog(@"Task terminated");

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self receiveDataFrom:outHandle to:outputBuffer with:@selector(receivedOutput:)];
    [self receiveDataFrom:errHandle to:errorBuffer with:@selector(receivedError:)];
    
    terminated = YES;

    [delegate terminated];

}

- (void) execute
{
	[task setLaunchPath:path];
	[task setArguments:args];

	NSPipe *outPipe = [NSPipe pipe];
	NSPipe *errPipe = [NSPipe pipe];

    [task setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
    [task setStandardOutput:outPipe];
    [task setStandardError:errPipe];

    outHandle = [outPipe fileHandleForReading];
    errHandle = [errPipe fileHandleForReading];	

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(outData:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:outHandle];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(errData:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:errHandle];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(terminated:)
                                                 name:NSTaskDidTerminateNotification
                                               object:task];

    [outHandle waitForDataInBackgroundAndNotify];
    [errHandle waitForDataInBackgroundAndNotify];

	[task launch];
}

-(void)abort
{
    [task terminate];
}

-(void)dealloc
{
    [delegate release];
    [args release];
    [path release];

    [outputBuffer release];
    [errorBuffer release];

    [task release];

    [super dealloc];
}

@end

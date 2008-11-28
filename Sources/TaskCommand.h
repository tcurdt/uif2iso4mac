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

#import <Cocoa/Cocoa.h>

@protocol TaskCommandDelegate < NSObject >

- (void) receivedOutput:(NSString*)output;
- (void) receivedError:(NSString*)error;
- (void) terminated;
- (NSString*) readInput;

@end

@interface TaskCommand : NSObject {

    NSTask *task;

    NSString *path;
    NSArray *args;

    id<TaskCommandDelegate> delegate;
    
    NSFileHandle *outHandle;
    NSFileHandle *errHandle;

    NSMutableString *errorBuffer;
    NSMutableString *outputBuffer;
    
    BOOL terminated;
}


- (id) initWithPath:(NSString*)path;
- (void) setArgs:(NSArray*)args;
- (void) execute;
- (void) abort;

- (id<TaskCommandDelegate>) delegate;
- (void) setDelegate:(id<TaskCommandDelegate>)delegate;

@end

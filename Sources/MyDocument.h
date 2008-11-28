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
#import "TaskCommand.h"

@interface MyDocument : NSDocument<TaskCommandDelegate>
{
    IBOutlet NSTextField *sizeField;
    IBOutlet NSTextField *versionField;
    IBOutlet NSTextField *imageTypeField;
    IBOutlet NSTextField *hashField;
    IBOutlet NSTextField *statusField;

    IBOutlet NSProgressIndicator *progressIndicator;

    IBOutlet NSButton *abortButton;

    TaskCommand *cmd;
    
    NSString *error;
    
    NSString *targetName;
    BOOL aborting;
    BOOL done;
}

- (IBAction) abort:(id)sender;

@end

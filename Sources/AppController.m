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

#import "AppController.h"
#import <FeedbackReporter/FRFeedbackReporter.h>
#import <Sparkle/SUUpdater.h>
#import <uuid/uuid.h>

#define U2IF4_INSTALLATIONID @"U2IF4InstallationId"

@implementation AppController

- (id) init
{
    self = [super init];

    return self;
}

- (void) awakeFromNib
{
    [[NSApplication sharedApplication] setDelegate:self];

    [[SUUpdater sharedUpdater] setDelegate:self];
 
    [[FRFeedbackReporter sharedReporter] reportIfCrash];   
}

- (NSString*)installationId
{
    NSString *uuid = [[NSUserDefaults standardUserDefaults] valueForKey:U2IF4_INSTALLATIONID];

    if (uuid == nil) {

        uuid_t buffer;
        
        uuid_generate(buffer);

        char str[37];

        uuid_unparse_upper(buffer, str);
        
        uuid = [NSString stringWithFormat:@"%s", str];

        NSLog(@"Generated UUID %@", uuid);
        
        [[NSUserDefaults standardUserDefaults] setValue: uuid
                                                 forKey: U2IF4_INSTALLATIONID];
    }

    return uuid;
}

- (NSArray *)feedParametersForUpdater:(SUUpdater *)updater sendingSystemProfile:(BOOL)sendingProfile
{
    NSLog(@"Adding parameters to sparkle check");

	NSArray *keys = [NSArray arrayWithObjects:@"key", @"value", nil];

    NSArray *parameters = [NSArray arrayWithObject:
        [NSDictionary dictionaryWithObjects:
        [NSArray arrayWithObjects:
        @"installationId", [self installationId], nil]
        forKeys:keys]];

    return parameters;
}

- (IBAction)showHelp:(id)sender
{
    NSString *url = @"http://getsatisfaction.com/vaferorg/products/vaferorg_uif2iso4mac";
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (IBAction)sendFeedback:(id)sender
{
    [[FRFeedbackReporter sharedReporter] reportFeedback];   
}

- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return NO;
}

@end

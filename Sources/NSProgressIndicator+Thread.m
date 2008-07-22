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

#import "NSProgressIndicator+Thread.h"


@implementation NSProgressIndicator (Thread)

- (void)_setMinValue:(NSNumber*)number
{
    [self setMinValue:[number doubleValue]];
}

- (void)_setMaxValue:(NSNumber*)number
{
    [self setMaxValue:[number doubleValue]];
}

- (void)_setDoubleValue:(NSNumber*)number
{
    [self setDoubleValue:[number doubleValue]];
}

- (void)onMainStartAnimation:(id)ref
{
    [self performSelectorOnMainThread:@selector(startAnimation:) withObject:ref waitUntilDone:YES];
}

- (void)onMainSetMinValue:(double)min
{
    [self performSelectorOnMainThread:@selector(_setMinValue:) withObject:[NSNumber numberWithDouble:min] waitUntilDone:YES];
}

- (void)onMainSetMaxValue:(double)max
{
    [self performSelectorOnMainThread:@selector(_setMaxValue:) withObject:[NSNumber numberWithDouble:max] waitUntilDone:YES];
}

- (void)onMainSetDoubleValue:(double)value
{
    [self performSelectorOnMainThread:@selector(_setDoubleValue:) withObject:[NSNumber numberWithDouble:value] waitUntilDone:YES];
    [self performSelectorOnMainThread:@selector(displayIfNeeded) withObject:nil waitUntilDone:YES];
}

- (void)onMainStopAnimation:(id)ref
{
    [self performSelectorOnMainThread:@selector(stopAnimation:) withObject:ref waitUntilDone:YES];
}

@end

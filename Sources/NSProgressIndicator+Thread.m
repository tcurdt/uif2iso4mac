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

#import <Cocoa/Cocoa.h>


@interface NSProgressIndicator (Thread)

- (void)onMainStartAnimation:(id)ref;
- (void)onMainSetMinValue:(double)min;
- (void)onMainSetMaxValue:(double)max;
- (void)onMainSetDoubleValue:(double)value;
- (void)onMainStopAnimation:(id)ref;

@end

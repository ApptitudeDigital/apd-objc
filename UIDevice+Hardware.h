
#import <UIKit/UIKit.h>

@interface UIDevice (Hardware)
- (NSString *) deviceName;
- (BOOL) isSimulator;
- (BOOL) isIpad;
- (BOOL) isIphone;
- (BOOL) isIphone4Or4S;
- (BOOL) is32AspectRatio;
- (BOOL) is43AspectRatio;
- (BOOL) is169AspectRatio;
@end

#import <UIKit/UIKit.h>
#import "UIView+AutoLayout.h"
#import "UIView+LayoutHelpers.h"

@interface APDLoadingView : UIView

@property UIActivityIndicatorView *activityIndicator;

- (void)start;
- (void)stop;

@end

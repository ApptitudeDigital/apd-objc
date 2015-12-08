
#import <UIKit/UIKit.h>

@class UIViewControllerStack;

typedef NS_ENUM(NSInteger,UIViewControllerStackOperation) {
	UIViewControllerStackOperationPush,
	UIViewControllerStackOperationPop
};

extern NSString * const UIViewControllerStackNotificationWillPush;
extern NSString * const UIViewControllerStackNotificationDidPush;
extern NSString * const UIViewControllerStackNotificationWillPop;
extern NSString * const UIViewControllerStackNotificationDidPop;

@protocol UIViewControllerStackUpdating <NSObject>
@optional
- (void) viewStack:(UIViewControllerStack *) viewStack willShowView:(UIViewControllerStackOperation) operation wasAnimated:(BOOL) wasAnimated;
- (void) viewStack:(UIViewControllerStack *) viewStack willHideView:(UIViewControllerStackOperation) operation wasAnimated:(BOOL) wasAnimated;
- (void) viewStack:(UIViewControllerStack *) viewStack didShowView:(UIViewControllerStackOperation) operation wasAnimated:(BOOL) wasAnimated;
- (void) viewStack:(UIViewControllerStack *) viewStack didHideView:(UIViewControllerStackOperation) operation wasAnimated:(BOOL) wasAnimated;
- (void) viewStack:(UIViewControllerStack *) viewStack didResizeViewController:(UIViewController *) viewController;
- (BOOL) shouldResizeFrameForStackPush:(UIViewControllerStack *) viewStack;
- (CGRect) viewFrameForViewStackController:(UIViewControllerStack *) viewStack isScrollView:(BOOL) isScrollView;
- (CGFloat) minViewHeightForViewStackController:(UIViewControllerStack *) viewStack isScrollView:(BOOL) isScrollView;

@end

IB_DESIGNABLE
@interface UIViewControllerStack : UIScrollView

//animation duration for push/popping view controllers that slide in / out.
@property IBInspectable CGFloat animationDuration;

//this always matches width/height. UIViewControllerStackViewResizing options are ignored.
@property IBInspectable BOOL alwaysResizePushedViews;

//methods for pushing/popping and altering what's displayed.
- (void) pushViewController:(UIViewController *) viewController animated:(BOOL) animated;
- (void) popViewControllerAnimated:(BOOL) animated;
- (void) popToRootViewControllerAnimated:(BOOL) animated;
- (void) popToViewControllerInStackAtIndex:(NSUInteger) index animated:(BOOL) animated;
- (void) eraseStackAndPushViewController:(UIViewController *) viewController animated:(BOOL) animated;
- (void) replaceCurrentViewControllerWithViewController:(UIViewController *) viewController animated:(BOOL) animated;
- (void) pushViewControllers:(NSArray *) viewControllers animated:(BOOL) animated;

//util methods for updating what's in the stack without effecting what's displayed.
- (void) pushViewControllers:(NSArray *) viewControllers;
- (void) insertViewController:(UIViewController *) viewController atIndex:(NSInteger) index;
- (void) replaceViewController:(UIViewController *) viewController withViewController:(UIViewController *) newViewController;

//completely erase stack and remove all subviews.
- (void) eraseStack;

//other utils
- (BOOL) canPopViewController;
- (BOOL) hasViewController:(UIViewController *) viewController;
- (BOOL) hasViewControllerClass:(Class) cls;
- (NSInteger) stackSize;
- (UIViewController *) currentViewController;
- (NSArray *) allViewControllers;

@end

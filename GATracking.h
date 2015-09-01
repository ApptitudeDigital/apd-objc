
#import <Foundation/Foundation.h>
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "GAIEcommerceFields.h"
#import "GAIEcommerceProduct.h"
#import "GAIEcommerceProductAction.h"
#import "TAGDataLayer.h"
#import "TAGManager.h"
#import "TAGContainerOpener.h"
#import "TAGContainer.h"

@interface GATracking : NSObject <TAGContainerOpenerNotifier>

//standard google analytics tracking
+ (void) initializeGoogleAnalyticsWithKey:(NSString *) key allowIDFACollection:(BOOL) allowIDFACollection; //call this before using standard any tracking methods.
+ (void) startSession; //call this in applicationDidBecomeActive:
+ (void) endSession;   //call this in applicationWillTerminate:
+ (void) trackScreen:(NSString *) screen;
+ (void) trackEventWithCategory:(NSString *) category action:(NSString *) action label:(NSString *) label;
+ (void) trackEventWithCategory:(NSString *) category action:(NSString *) action label:(NSString *) label andValue:(NSInteger) val;

//TagManager methods. These require using [GATracking instance];
@property TAGContainer * container;
+ (GATracking *) instance;
- (void) initTagManagerWithID:(NSString *) tagManagerId;
- (void) trackScreenWithTagManager:(NSString *) screenName;
- (void) trackEventWithTagManager:(NSString *) event parameters:(NSDictionary *) parameters;

@end

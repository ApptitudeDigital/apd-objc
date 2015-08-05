
#import <Foundation/Foundation.h>
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "GAIEcommerceFields.h"
#import "GAIEcommerceProduct.h"
#import "GAIEcommerceProductAction.h"

/**
 You can define GATracking_GATagManager in order to enable tag manager
 part of google analytics library. You must define GATracking_TAGManager
 before importing this header.
 
 #define GATracking_GATagManager 1
 #import "GATracking.h"
**/
#ifdef GATracking_GATagManager
#import "TAGDataLayer.h"
#import "TAGManager.h"
#import "TAGContainerOpener.h"
#import "TAGContainer.h"
#endif

#ifdef GATracking_GATagManager
@interface GATracking : NSObject <TAGContainerOpenerNotifier>
#else
@interface GATracking : NSObject
#endif

//standard google analytics tracking
+ (void) initializeGoogleAnalyticsWithKey:(NSString *) key allowIDFACollection:(BOOL) allowIDFACollection; //call this before using standard any tracking methods.
+ (void) startSession; //call this in applicationDidBecomeActive:
+ (void) endSession;   //call this in applicationWillTerminate:
+ (void) trackScreen:(NSString *) screen;
+ (void) trackEventWithCategory:(NSString *) category action:(NSString *) action label:(NSString *) label;
+ (void) trackEventWithCategory:(NSString *) category action:(NSString *) action label:(NSString *) label andValue:(NSInteger) val;

//TagManager methods. These require using [GATracking instance];
#ifdef GATracking_GATagManager
@property TAGContainer * container;
+ (GATracking *) instance;
- (void) initTagManagerWithID:(NSString *) tagManagerId;
- (void) trackScreenWithTagManager:(NSString *) screenName;
- (void) trackEventWithTagManager:(NSString *) event parameters:(NSDictionary *) parameters;
#endif

@end

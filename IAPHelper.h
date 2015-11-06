
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

extern NSString * const IAPHelperDomain;
extern const NSInteger IAPHelperErrorCodeProductNotFound;
extern const NSInteger IAPHelperErrorCodeNoProducts;

//when initial product load from itunes completes.
typedef void(^IAPHelperLoadProductsCompletion)(NSError * error);

//when a purchase completes.
typedef void(^IAPHelperPurchaseProductCompletion)(NSError * error, SKPaymentTransaction * transaction);

//called for each product that is restored.
//When all restores are completed the 'completed' flag is TRUE.
typedef void(^IAPHelperRestorePurchasesCompletion)(NSError * error, SKPaymentTransaction * transaction, BOOL completed);

@interface IAPHelper : NSObject <SKProductsRequestDelegate,SKPaymentTransactionObserver>

//returns all product ids from InAppPurchases.plist
+ (NSArray *) allProductIdsFromPlist;

//get product ids by name from InAppPurchases.plist
+ (NSArray *) productsFromPlistByName:(NSArray *) productNames;

//gets a single product id by name from the InAppPurchases.plist.
+ (NSString *) productFromPlistByName:(NSString *) name;

//load product information from itunes.
- (void) loadItunesProducts:(NSArray *) productIds withCompletion:(IAPHelperLoadProductsCompletion) completion;

//restore all purchases
- (void) restorePurchasesWithCompletion:(IAPHelperRestorePurchasesCompletion) completion;

//purchase a product id.
- (void) purchaseItunesProductId:(NSString *) productId completion:(IAPHelperPurchaseProductCompletion) completion;
- (void) purchaseItunesProductId:(NSString *) productId quantity:(NSInteger) quantity completion:(IAPHelperPurchaseProductCompletion) completion;

//some utilities for display prices.
- (NSString *) currencyCode;
- (NSNumber *) priceForItunesProductId:(NSString *) productId;
- (NSString *) priceStringForItunesProductId:(NSString *) productId;
- (SKProduct *) productForItunesProductId:(NSString *) productId;

@end

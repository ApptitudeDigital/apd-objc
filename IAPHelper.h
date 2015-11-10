
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

//returns productInfo from InAppPurchases.plist.
+ (NSArray *) defaultProductInfo;

//returns IAPHelper where productInfo comes from InAppPurchases.plist.
+ (IAPHelper *) defaultHelper;

//Example Product Info:
//<?xml version="1.0" encoding="UTF-8"?>
//<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
//<plist version="1.0">
//<array>
// <dict>
//  <key>Name</key>
//  <string>NewBoard</string>
//  <key>ProductId</key>
//  <string>com.apptitude.SmilesAndFrowns.NewBoard</string>
//  <key>Type</key>
//  <string>Consumable</string>
// </dict>
// <dict>
//  <key>Name</key>
//  <string>RemoveAds</string>
//  <key>ProductId</key>
//  <string>com.apptitude.SmilesAndFrowns.RemoveAds</string>
//  <key>Type</key>
//  <string>Non-Consumable</string>
// </dict>
//</array>
//</plist>
- (id) initWithProductInfo:(NSArray *) productInfo;

//utilities for getting info from product info
- (NSArray *) productIdsByNames:(NSArray *) productNames;
- (NSString *) productIdByName:(NSString *) productName;
- (NSString *) productTypeForProductId:(NSString *) productId;
- (NSString *) productNameByProductId:(NSString *) productId;
- (BOOL) hasPurchasedNonConsumableNamed:(NSString *) productNameInPlist;

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

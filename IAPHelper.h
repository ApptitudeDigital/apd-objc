
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

//All Product Ids must be in a plist called InAppPurchases.plist
//Example:
//<?xml version="1.0" encoding="UTF-8"?>
//<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
//<plist version="1.0">
//<array>
// <dict>
//  <key>Name</key>
//  <string>AllSymbols</string>
//  <key>ProductId</key>
//  <string>com.hirschdenberg.modmath.AllSymbols</string>
// </dict>
// <dict>
//  <key>Name</key>
//  <string>Infinity</string>
//  <key>ProductId</key>
//  <string>com.hirschdenberg.modmath.Infinity</string>
// </dict>
//</array>
//</plist>
- (void) loadItunesProductsCompletion:(IAPHelperLoadProductsCompletion) completion;

//this looks up a product id by name in the InAppPurchases.plist resource.
- (NSString *) productIdForName:(NSString *) productName;

//restore all purchases
//StoreRestoreCompletedNotification / StoreRestoreFailedNotification
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

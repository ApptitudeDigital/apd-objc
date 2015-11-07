
#import "IAPHelper.h"

#define IAPHelperNonConsumableDefaultsKey @"IAPHelperPurchasedNonConsumables"

NSString * const IAPHelperDomain = @"com.apptitude.IAPHelper";
const NSInteger IAPHelperErrorCodeProductNotFound = 1;
const NSInteger IAPHelperErrorCodeNoProducts = 2;

@interface IAPHelper ()
@property BOOL isRestoring;
@property NSArray * productIds;
@property NSArray * skproducts;
@property (strong) IAPHelperRestorePurchasesCompletion restorePurchasesCompletion;
@property (strong) IAPHelperLoadProductsCompletion loadProductsCompletion;
@property (strong) IAPHelperPurchaseProductCompletion purchaseProductCompletion;
@end

@implementation IAPHelper

+ (NSDictionary *) productInfoDictForName:(NSString *) productName {
	NSString * plistFile = [[NSBundle mainBundle] pathForResource:@"InAppPurchases" ofType:@"plist"];
	NSArray * inAppPurchases = [NSArray arrayWithContentsOfFile:plistFile];
	for(NSDictionary * item in inAppPurchases) {
		if([item[@"Name"] isEqualToString:productName]) {
			return item;
		}
	}
	return nil;
}

+ (NSDictionary *) productInfoDictForProductId:(NSString *) productId {
	NSString * plistFile = [[NSBundle mainBundle] pathForResource:@"InAppPurchases" ofType:@"plist"];
	NSArray * inAppPurchases = [NSArray arrayWithContentsOfFile:plistFile];
	for(NSDictionary * item in inAppPurchases) {
		if([item[@"ProductId"] isEqualToString:productId]) {
			return item;
		}
	}
	return nil;
}

+ (BOOL) hasPurchasedNonConsumableNamed:(NSString *) productNameInPlist; {
	NSDictionary * defaults = @{IAPHelperNonConsumableDefaultsKey:@{}};
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	NSString * productId = [IAPHelper productIdByName:productNameInPlist];
	if(!productId) {
		return FALSE;
	}
	NSDictionary * purchased = [[NSUserDefaults standardUserDefaults] objectForKey:IAPHelperNonConsumableDefaultsKey];
	if(purchased[productId]) {
		return [purchased[productId] boolValue];
	}
	return FALSE;
}

+ (BOOL) hasPurchasedNonConsumableProductId:(NSString *) productId; {
	NSDictionary * defaults = @{IAPHelperNonConsumableDefaultsKey:@{}};
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	NSDictionary * purchased = [[NSUserDefaults standardUserDefaults] objectForKey:IAPHelperNonConsumableDefaultsKey];
	if(purchased[productId]) {
		return [purchased[productId] boolValue];
	}
	return FALSE;
}

+ (NSArray *) allProductIds; {
	NSMutableArray * products = [NSMutableArray array];
	NSString * plistFile = [[NSBundle mainBundle] pathForResource:@"InAppPurchases" ofType:@"plist"];
	NSArray * inAppPurchases = [NSArray arrayWithContentsOfFile:plistFile];
	for(NSDictionary * item in inAppPurchases) {
		[products addObject:item[@"ProductId"]];
	}
	return products;
}

+ (NSString *) productNameByProductId:(NSString *) productId; {
	NSDictionary * info = [IAPHelper productInfoDictForProductId:productId];
	return info[@"Name"];
}

+ (NSArray *) productIdsByNames:(NSArray *) productNames; {
	NSMutableArray * products = [NSMutableArray array];
	for(NSString * productName in productNames) {
		NSDictionary * info = [IAPHelper productInfoDictForName:productName];
		[products addObject:info[@"ProductId"]];
	}
	return products;
}

+ (NSString *) productIdByName:(NSString *) productName; {
	NSDictionary * info = [IAPHelper productInfoDictForName:productName];
	return info[@"ProductId"];
}

+ (NSString *) productTypeForProductId:(NSString *) productId {
	NSDictionary * info = [IAPHelper productInfoDictForProductId:productId];
	return info[@"Type"];
}

+ (NSString *) productTypeForName:(NSString *) productName {
	NSDictionary * info = [IAPHelper productInfoDictForName:productName];
	return info[@"Type"];
}

- (id) init {
	self = [super init];
	self.productIds = nil;
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
	return self;
}

- (void) dealloc {
	self.restorePurchasesCompletion = nil;
	self.loadProductsCompletion = nil;
	self.purchaseProductCompletion = nil;
}

- (NSString *) currencyCode {
	return [[NSLocale currentLocale] objectForKey:NSLocaleCurrencyCode];
}

- (NSNumber *) priceForItunesProductId:(NSString *) productId {
	SKProduct * product = nil;
	for(product in self.skproducts) {
		if([product.productIdentifier isEqualToString:productId]) {
			break;
		}
	}
	if(!product) {
		return @(0);
	}
	return product.price;
}

- (SKProduct *) productForItunesProductId:(NSString *) productId {
	for(SKProduct * product in self.skproducts) {
		if([product.productIdentifier isEqualToString:productId]) {
			return product;
		}
	}
	return nil;
}

- (NSString *) priceStringForItunesProductId:(NSString *) productId {
	SKProduct * product = nil;
	for(product in self.skproducts) {
		if([product.productIdentifier isEqualToString:productId]) {
			break;
		}
	}
	if(!product) {
		return @"";
	}
	NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[numberFormatter setLocale:product.priceLocale];
	NSString * formattedPrice = [numberFormatter stringFromNumber:product.price];
	return formattedPrice;
}

- (void) loadItunesProducts:(NSArray *) productIds withCompletion:(IAPHelperLoadProductsCompletion) completion {
	self.loadProductsCompletion = completion;
	self.productIds = productIds;
	NSLog(@"loading products: %@",self.productIds);
	SKProductsRequest * productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:self.productIds]];
	productsRequest.delegate = self;
	[productsRequest start];
}

- (void) productsRequest:(SKProductsRequest *) request didReceiveResponse:(SKProductsResponse *)response {
	self.skproducts = response.products;
	dispatch_async(dispatch_get_main_queue(), ^{
		self.loadProductsCompletion(nil);
	});
}

- (void) request:(SKRequest *) request didFailWithError:(NSError *)error {
	dispatch_async(dispatch_get_main_queue(), ^{
		self.loadProductsCompletion(error);
	});
}

- (void) purchaseItunesProductId:(NSString *) productId completion:(IAPHelperPurchaseProductCompletion)completion {
	return [self purchaseItunesProductId:productId quantity:1 completion:completion];
}

- (void) purchaseItunesProductId:(NSString *) productId quantity:(NSInteger) quantity completion:(IAPHelperPurchaseProductCompletion)completion {
	SKProduct * purchaseProduct = nil;
	
	for(SKProduct * product in self.skproducts) {
		if([product.productIdentifier isEqualToString:productId]) {
			purchaseProduct = product;
			break;
		}
	}
	
	if(!purchaseProduct) {
		return completion([NSError errorWithDomain:IAPHelperDomain code:IAPHelperErrorCodeProductNotFound userInfo:@{NSLocalizedDescriptionKey:@"Product not loaded from iTunes Connect."}],nil);
	}
	
	self.purchaseProductCompletion = completion;
	
	SKMutablePayment * payment = [SKMutablePayment paymentWithProduct:purchaseProduct];
	payment.quantity = quantity;
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void) paymentQueue:(SKPaymentQueue *) queue updatedTransactions:(NSArray *) transactions {
	for(SKPaymentTransaction * transaction in transactions) {
		if(transaction.transactionState == SKPaymentTransactionStatePurchased) {
			[self persistTransaction:transaction];
			[self completeTransaction:transaction];
		}
		
		if(transaction.transactionState == SKPaymentTransactionStateRestored) {
			[self persistTransaction:transaction];
			[self restoreTransaction:transaction];
		}
		
		if(transaction.transactionState == SKPaymentTransactionStateFailed) {
			[self failedTransaction:transaction];
		}
	}
}

- (void) persistTransaction:(SKPaymentTransaction *) transaction {
	NSString * type = [IAPHelper productTypeForProductId:transaction.payment.productIdentifier];
	
	//only non-consumables are stored in defaults.
	if([type isEqualToString:@"Non-Consumable"]) {
		NSDictionary * defaults = @{IAPHelperNonConsumableDefaultsKey:@{}};
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
		
		NSDictionary * purchases = [[NSUserDefaults standardUserDefaults] objectForKey:IAPHelperNonConsumableDefaultsKey];
		NSMutableDictionary * updates = [NSMutableDictionary dictionaryWithDictionary:purchases];
		updates[transaction.payment.productIdentifier] = @(TRUE);
		
		[[NSUserDefaults standardUserDefaults] setObject:updates forKey:IAPHelperNonConsumableDefaultsKey];
	}
}

- (void) completeTransaction:(SKPaymentTransaction *) transaction {
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	if(self.purchaseProductCompletion) {
		self.purchaseProductCompletion(nil,transaction);
	}
}

- (void) restoreTransaction:(SKPaymentTransaction *) transaction {
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	if(self.restorePurchasesCompletion) {
		self.restorePurchasesCompletion(nil,transaction,FALSE);
	}
}

- (void) failedTransaction:(SKPaymentTransaction *) transaction {
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	if(self.purchaseProductCompletion) {
		self.purchaseProductCompletion(transaction.error,nil);
	}
}

- (void) restorePurchasesWithCompletion:(IAPHelperRestorePurchasesCompletion) completion {
	self.isRestoring = TRUE;
	self.restorePurchasesCompletion = completion;
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void) paymentQueue:(SKPaymentQueue *) queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
	self.isRestoring = FALSE;
	if(self.restorePurchasesCompletion) {
		self.restorePurchasesCompletion(error,nil,TRUE);
	}
}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
	self.isRestoring = FALSE;
	if(self.restorePurchasesCompletion) {
		self.restorePurchasesCompletion(nil,nil,TRUE);
	}
}

@end

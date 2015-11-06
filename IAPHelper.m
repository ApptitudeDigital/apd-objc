
#import "IAPHelper.h"

NSString * const IAPHelperDomain = @"IAPHelperDomain";
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

- (UIViewController *) rootViewController {
	NSObject <UIApplicationDelegate> * appDelegate = [UIApplication sharedApplication].delegate;
	UIViewController * root = appDelegate.window.rootViewController;
	return root;
}

- (void) loadItunesProductsCompletion:(IAPHelperLoadProductsCompletion) completion {
	self.loadProductsCompletion = completion;
	[self readProductIdsFromPlist];
	if(!self.productIds) {
		return completion([NSError errorWithDomain:IAPHelperDomain code:IAPHelperErrorCodeNoProducts userInfo:nil]);
	}
	NSLog(@"loading products: %@",self.productIds);
	SKProductsRequest * productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:self.productIds]];
	productsRequest.delegate = self;
	[productsRequest start];
}

- (void) productsRequest:(SKProductsRequest *) request didReceiveResponse:(SKProductsResponse *)response {
	self.skproducts = response.products;
	dispatch_sync(dispatch_get_main_queue(), ^{
		self.loadProductsCompletion(nil);
	});
}

- (void) request:(SKRequest *) request didFailWithError:(NSError *)error {
	dispatch_sync(dispatch_get_main_queue(), ^{
		self.loadProductsCompletion(nil);
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
		return completion([NSError errorWithDomain:IAPHelperDomain code:IAPHelperErrorCodeProductNotFound userInfo:nil],nil);
	}
	
	self.purchaseProductCompletion = completion;
	
	SKMutablePayment * payment = [SKMutablePayment paymentWithProduct:purchaseProduct];
	payment.quantity = quantity;
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void) paymentQueue:(SKPaymentQueue *) queue updatedTransactions:(NSArray *) transactions {
	for(SKPaymentTransaction * transaction in transactions) {
		if(transaction.transactionState == SKPaymentTransactionStatePurchased) {
			[self completeTransaction:transaction];
		}
		
		if(transaction.transactionState == SKPaymentTransactionStateRestored) {
			[self restoreTransaction:transaction];
		}
		
		if(transaction.transactionState == SKPaymentTransactionStateFailed) {
			[self failedTransaction:transaction];
		}
	}
}

- (void) completeTransaction:(SKPaymentTransaction *) transaction {
	if(self.purchaseProductCompletion) {
		self.purchaseProductCompletion(nil,transaction);
	}
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void) restoreTransaction:(SKPaymentTransaction *) transaction {
	if(self.restorePurchasesCompletion) {
		self.restorePurchasesCompletion(nil,transaction,FALSE);
	}
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void) failedTransaction:(SKPaymentTransaction *) transaction {
	if(self.purchaseProductCompletion) {
		self.purchaseProductCompletion(transaction.error,nil);
	}
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
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

- (NSString *) productIdForName:(NSString *) productName; {
	NSString * plistFile = [[NSBundle mainBundle] pathForResource:@"InAppPurchases" ofType:@"plist"];
	NSArray * inAppPurchases = [NSArray arrayWithContentsOfFile:plistFile];
	for(NSDictionary * item in inAppPurchases) {
		if([item[@"Name"] isEqualToString:productName]) {
			return item[@"ProductId"];
		}
	}
	return nil;
}

- (void) readProductIdsFromPlist {
	NSString * plist = [[NSBundle mainBundle] pathForResource:@"InAppPurchases" ofType:@"plist"];
	if(!plist) {
		@throw [NSException exceptionWithName:@"IAPHelperPlistNotFound" reason:@"InAppPurchases.plist not found in bundle." userInfo:nil];
	}
	NSArray * items = [NSArray arrayWithContentsOfFile:plist];
	NSMutableArray * productdIds = [NSMutableArray array];
	for(NSDictionary * item in items) {
		[productdIds addObject:item[@"ProductId"]];
	}
	self.productIds = productdIds;
}

@end

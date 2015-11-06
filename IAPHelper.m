
#import "IAPHelper.h"

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

+ (NSArray *) productsFromPlistByName:(NSArray *) productNames {
	NSMutableArray * products = [NSMutableArray array];
	NSString * plistFile = [[NSBundle mainBundle] pathForResource:@"InAppPurchases" ofType:@"plist"];
	NSArray * inAppPurchases = [NSArray arrayWithContentsOfFile:plistFile];
	for(NSString * productName in productNames) {
		for(NSDictionary * item in inAppPurchases) {
			if([item[@"Name"] isEqualToString:productName]) {
				[products addObject:item[@"ProductId"]];
			}
		}
	}
	return products;
}

+ (NSString *) productFromPlistByName:(NSString *) productName; {
	NSString * plistFile = [[NSBundle mainBundle] pathForResource:@"InAppPurchases" ofType:@"plist"];
	NSArray * inAppPurchases = [NSArray arrayWithContentsOfFile:plistFile];
	for(NSDictionary * item in inAppPurchases) {
		if([item[@"Name"] isEqualToString:productName]) {
			return item[@"ProductId"];
		}
	}
	return nil;
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

- (UIViewController *) rootViewController {
	NSObject <UIApplicationDelegate> * appDelegate = [UIApplication sharedApplication].delegate;
	UIViewController * root = appDelegate.window.rootViewController;
	return root;
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
		dispatch_async(dispatch_get_main_queue(), ^{
			self.purchaseProductCompletion(nil,transaction);
		});
	}
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void) restoreTransaction:(SKPaymentTransaction *) transaction {
	if(self.restorePurchasesCompletion) {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.restorePurchasesCompletion(nil,transaction,FALSE);
		});
	}
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void) failedTransaction:(SKPaymentTransaction *) transaction {
	if(self.purchaseProductCompletion) {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.purchaseProductCompletion(transaction.error,nil);
		});
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
		dispatch_async(dispatch_get_main_queue(), ^{
			self.restorePurchasesCompletion(error,nil,TRUE);
		});
	}
}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
	self.isRestoring = FALSE;
	if(self.restorePurchasesCompletion) {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.restorePurchasesCompletion(nil,nil,TRUE);
		});
	}
}

@end

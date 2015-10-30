
#import "UIAlertAction+Additions.h"

@implementation UIAlertAction (Additions)

+ (UIAlertAction *) OKAction; {
	return [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
}

+ (UIAlertAction *) OKActionWithCompletion:(void (^)(UIAlertAction *action)) completion; {
	return [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:completion];
}

@end

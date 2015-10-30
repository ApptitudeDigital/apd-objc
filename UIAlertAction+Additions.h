
#import <UIKit/UIKit.h>

@interface UIAlertAction (Additions)

+ (UIAlertAction *) OKAction;
+ (UIAlertAction *) OKActionWithCompletion:(void (^)(UIAlertAction *action)) completion;

@end

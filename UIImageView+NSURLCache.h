
#import <UIKit/UIKit.h>

extern NSString * const UIImageViewNSURLCacheErrorDomain;
extern const NSInteger UIImageViewNSURLCacheErrorResponseCode;
extern const NSInteger UIimageViewNSURLCacheErrorContentType;

typedef void(^UIImageViewNSURLCache)(NSError * error, UIImage * image);

@interface UIImageView (NSURLCache)

+ (void) setDefaultAuthBasicUsername:(NSString *) username password:(NSString *) password;
- (void) setImageForURL:(NSURL *) url withCompletion:(UIImageViewNSURLCache) completion;
- (void) setImageForURL:(NSURL *) url authBasicWithUsername:(NSString *) username password:(NSString *) password withCompletion:(UIImageViewNSURLCache)completion;
- (void) setImageWithDefaultAuthBasicForURL:(NSURL *) url withCompletion:(UIImageViewNSURLCache) completion;
- (void) setImageForRequest:(NSURLRequest *) request withCompletion:(UIImageViewNSURLCache) completion;

@end

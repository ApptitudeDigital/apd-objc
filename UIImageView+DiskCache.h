
#import <UIKit/UIKit.h>

extern NSString * const UIImageViewDiskCacheErrorDomain;
extern const NSInteger UIImageViewDiskCacheErrorResponseCode;
extern const NSInteger UIImageViewDiskCacheErrorContentType;

typedef void(^UIImageViewDiskCacheCompletion)(NSError * error, UIImage * image);

@interface UIImageView (DiskCache)

+ (void) setCacheDir:(NSURL *) dirURL;
+ (void) clearCachedFilesOlderThan1Day;
+ (void) clearCachedFilesOlderThan1Week;
+ (void) clearCachedFilesOlderThan:(NSTimeInterval) timeInterval;
+ (void) setDefaultAuthBasicUsername:(NSString *) username password:(NSString *) password;

- (void) setImageForURL:(NSURL *) url withCompletion:(UIImageViewDiskCacheCompletion) completion;
- (void) setImageForURL:(NSURL *) url authBasicWithUsername:(NSString *) username password:(NSString *) password withCompletion:(UIImageViewDiskCacheCompletion)completion;
- (void) setImageWithDefaultAuthBasicForURL:(NSURL *) url withCompletion:(UIImageViewDiskCacheCompletion) completion;
- (void) setImageForRequest:(NSURLRequest *) request withCompletion:(UIImageViewDiskCacheCompletion) completion;

@end


#import <UIKit/UIKit.h>

extern NSString * const UIImageViewDiskCacheErrorDomain;
extern const NSInteger UIImageViewDiskCacheErrorResponseCode;
extern const NSInteger UIImageViewDiskCacheErrorContentType;

typedef void(^UIImageViewDiskCacheCompletion)(NSError * error, UIImage * image);

@interface UIImageViewCache : NSObject <NSCoding>
@property NSTimeInterval maxage;
@property NSString * etag;
@end

@interface UIImageView (DiskCache)

//set the cache dir. default is Home/Library/Caches/UIImageViewDiskCache
+ (void) setCacheDir:(NSURL *) dirURL;

//set the default Authorization header username/password.
+ (void) setDefaultAuthBasicUsername:(NSString *) username password:(NSString *) password;

//these ignore cache policies and delete files where the modified date is older than specified amount of time.
+ (void) clearCachedFilesOlderThan1Day;
+ (void) clearCachedFilesOlderThan1Week;
+ (void) clearCachedFilesOlderThan:(NSTimeInterval) timeInterval;

//uses cache-control policies from server if they are available. (Uses "Cache-Control max-age=n", and "ETag" headers internally)
//*** If caching policies aren't in place on server images will always load. **
- (void) setImageForURLWithCacheControl:(NSURL *) url withCompletion:(UIImageViewDiskCacheCompletion) completion;
- (void) setImageForURLWithCacheControl:(NSURL *) url authBasicUsername:(NSString *) username password:(NSString *) password withCompletion:(UIImageViewDiskCacheCompletion) completion;
- (void) setImageForURLWithCacheControlAndDefaultAuthBasic:(NSURL *) url withCompletion:(UIImageViewDiskCacheCompletion) completion;
- (void) setImageForRequestWithCacheControl:(NSURLRequest *) request withCompletion:(UIImageViewDiskCacheCompletion) completion;

//ignores Cache-Control and ETag headers from server. It's up to you to use +clearCachedFiles methods above to remove old files.
- (void) setImageForURL:(NSURL *) url withCompletion:(UIImageViewDiskCacheCompletion) completion;
- (void) setImageForURL:(NSURL *) url authBasicWithUsername:(NSString *) username password:(NSString *) password withCompletion:(UIImageViewDiskCacheCompletion)completion;
- (void) setImageWithDefaultAuthBasicForURL:(NSURL *) url withCompletion:(UIImageViewDiskCacheCompletion) completion;
- (void) setImageForRequest:(NSURLRequest *) request withCompletion:(UIImageViewDiskCacheCompletion) completion;

@end

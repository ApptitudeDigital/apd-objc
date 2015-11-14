
#import "UIImageView+DiskCache.h"
#import "NSMutableURLRequest+Additions.h"

NSString * const UIImageViewDiskCacheErrorDomain = @"com.apptitude.UIImageView+DisckCache";
const NSInteger UIImageViewDiskCacheErrorResponseCode = 1;
const NSInteger UIImageViewDiskCacheErrorContentType = 2;
const NSInteger UIImageViewDiskCacheErrorNilURL = 3;

static NSString * _authUsername;
static NSString * _authPassword;

static NSURL * _cacheDir;

@implementation UIImageView (DiskCache)

+ (void) initialize {
	NSURL * appSupport = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
	_cacheDir = [appSupport URLByAppendingPathComponent:@"UIImageViewDiskCache"];
	[[NSFileManager defaultManager] createDirectoryAtURL:_cacheDir withIntermediateDirectories:TRUE attributes:nil error:nil];
}

+ (void) clearCachedFilesOlderThan1Week {
	[UIImageView clearCachedFilesOlderThan:604800];
}

+ (void) clearCachedFilesOlderThan1Day {
	[UIImageView clearCachedFilesOlderThan:86400];
}

+ (void) clearCachedFilesOlderThan:(NSTimeInterval) timeInterval {
	dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0);
	dispatch_async(background, ^{
		NSArray * files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_cacheDir.path error:nil];
		for(NSString * file in files) {
			NSURL * path = [_cacheDir URLByAppendingPathComponent:file];
			NSDictionary * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path.path error:nil];
			NSDate * modified = attributes[NSFileModificationDate];
			NSTimeInterval diff = [[NSDate date] timeIntervalSinceDate:modified];
			if(diff > timeInterval) {
				NSLog(@"deleting cached file: %@",path.path);
				[[NSFileManager defaultManager] removeItemAtPath:path.path error:nil];
			}
		}
	});
}

+ (void) setCacheDir:(NSURL *) dirURL {
	_cacheDir = dirURL;
}

+ (void) setDefaultAuthBasicUsername:(NSString *) username password:(NSString *) password; {
	_authUsername = username;
	_authPassword = password;
}

- (NSURL *) localFileURLForURL:(NSURL *) url {
	if(!url) {
		return NULL;
	}
	//NSString * path1 = [url absoluteString];
	//NSString * path = (__bridge NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(CFAllocatorGetDefault(),(CFStringRef)path1,NULL,kCFStringEncodingUTF8);
	NSString * path = [url.absoluteString stringByRemovingPercentEncoding];
	NSString * path2 = [path stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	path2 = [path2 stringByReplacingOccurrencesOfString:@"https://" withString:@""];
	path2 = [path2 stringByReplacingOccurrencesOfString:@":" withString:@"-"];
	path2 = [path2 stringByReplacingOccurrencesOfString:@"?" withString:@"-"];
	path2 = [path2 stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	path2 = [path2 stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	return [_cacheDir URLByAppendingPathComponent:path2];
}

- (BOOL) acceptedContentType:(NSString *) contentType {
	NSArray * acceptedContentTypes = @[@"image/png",@"image/jpg",@"image/jpeg",@"image/bitmap"];
	return [acceptedContentTypes containsObject:contentType];
}

- (void) setImageInBackground:(NSURL *) cachedURL completion:(UIImageViewDiskCacheCompletion) completion {
	dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0);
	dispatch_async(background, ^{
		NSDate * modified = [NSDate date];
		NSDictionary * attributes = @{NSFileModificationDate:modified};
		NSError * error = nil;
		[[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:cachedURL.path error:&error];
		UIImage * image = [UIImage imageWithContentsOfFile:cachedURL.path];
		dispatch_async(dispatch_get_main_queue(), ^{
			self.image = image;
			completion(nil,image);
		});
	});
}

- (void) writeData:(NSData *) data toFile:(NSURL *) cachedURL {
	dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0);
	dispatch_async(background, ^{
		[data writeToFile:cachedURL.path atomically:TRUE];
	});
}

- (void) setImageForRequest:(NSURLRequest *) request withCompletion:(UIImageViewDiskCacheCompletion) completion {
	
	if(!request.URL) {
		NSLog(@"[UIImageView+NSURLCache] WARNING: request.URL was NULL");
		completion([NSError errorWithDomain:UIImageViewDiskCacheErrorDomain code:UIImageViewDiskCacheErrorNilURL userInfo:@{NSLocalizedDescriptionKey:@"request.URL is nil"}],nil);
	}
	
	NSURL * cachedURL = [self localFileURLForURL:request.URL];
	if([[NSFileManager defaultManager] fileExistsAtPath:cachedURL.path]) {
		[self setImageInBackground:cachedURL completion:completion];
		return;
	}
	
	NSLog(@"[UIImageView+NSURLCache] cache miss for url: %@",request.URL);
	
	NSURLSessionDataTask * imageTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if(error) {
				completion(error,nil);
				return;
			}
			
			NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
			if(httpResponse.statusCode != 200) {
				NSString * message = [NSString stringWithFormat:@"Invalid Image Cache Response %li",(long)httpResponse.statusCode];
				completion([NSError errorWithDomain:UIImageViewDiskCacheErrorDomain code:UIImageViewDiskCacheErrorResponseCode userInfo:@{NSLocalizedDescriptionKey:message}],nil);
				return;
			}
			
			NSString * contentType = [[httpResponse allHeaderFields] objectForKey:@"Content-Type"];
			if(![self acceptedContentType:contentType]) {
				completion([NSError errorWithDomain:UIImageViewDiskCacheErrorDomain code:UIImageViewDiskCacheErrorContentType userInfo:@{NSLocalizedDescriptionKey:@"Response was not an image"}],nil);
				return;
			}
			
			if(data) {
				self.image = [UIImage imageWithData:data];
				[self writeData:data toFile:cachedURL];
				completion(nil,self.image);
			}
		});
	}];
	
	[imageTask resume];
}

- (void) setImageForURL:(NSURL *) url withCompletion:(UIImageViewDiskCacheCompletion) completion; {
	NSURLRequest * request = [NSURLRequest requestWithURL:url];
	[self setImageForRequest:request withCompletion:completion];
}

- (void) setImageForURL:(NSURL *) url authBasicWithUsername:(NSString *) username password:(NSString *) password withCompletion:(UIImageViewDiskCacheCompletion)completion; {
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
	[request setAuthBasicHeaderUsername:username password:password];
	[self setImageForRequest:request withCompletion:completion];
}

- (void) setImageWithDefaultAuthBasicForURL:(NSURL *) url withCompletion:(UIImageViewDiskCacheCompletion) completion; {
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
	[request setAuthBasicHeaderUsername:_authUsername password:_authPassword];
	[self setImageForRequest:request withCompletion:completion];
}

@end

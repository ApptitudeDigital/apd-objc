
#import "UIImageView+DiskCache.h"
#import "NSTimer+Blocks.h"

NSString * const UIImageViewDiskCacheErrorDomain = @"com.apptitude.UIImageView+DisckCache";
const NSInteger UIImageViewDiskCacheErrorResponseCode = 1;
const NSInteger UIImageViewDiskCacheErrorContentType = 2;
const NSInteger UIImageViewDiskCacheErrorNilURL = 3;

static NSString * _auth;
static NSURL * _cacheDir;

@implementation UIImageViewCache

- (id) init {
	self = [super init];
	self.maxage = 0;
	self.etag = nil;
	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	self = [super init];
	NSKeyedUnarchiver * un = (NSKeyedUnarchiver *)aDecoder;
	self.maxage = [un decodeDoubleForKey:@"maxage"];
	self.etag = [un decodeObjectForKey:@"etag"];
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	NSKeyedArchiver * ar = (NSKeyedArchiver *)aCoder;
	[ar encodeObject:self.etag forKey:@"etag"];
	[ar encodeDouble:self.maxage forKey:@"maxage"];
}

@end

@implementation UIImageView (DiskCache)

+ (void) initialize {
	NSURL * appSupport = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
	_cacheDir = [appSupport URLByAppendingPathComponent:@"UIImageViewDiskCache"];
	[[NSFileManager defaultManager] createDirectoryAtURL:_cacheDir withIntermediateDirectories:TRUE attributes:nil error:nil];
}

+ (void) setCacheDir:(NSURL *) dirURL {
	_cacheDir = dirURL;
}

+ (void) setDefaultAuthBasicUsername:(NSString *) username password:(NSString *) password; {
	NSString * authString = [NSString stringWithFormat:@"%@:%@",username,password];
	NSData * authData = [authString dataUsingEncoding:NSUTF8StringEncoding];
	NSString * encoded = [authData base64EncodedStringWithOptions:0];
	_auth = [NSString stringWithFormat:@"Basic %@",encoded];
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

- (NSURL *) localCacheControlFileURLForURL:(NSURL *) url {
	if(!url) {
		return NULL;
	}
	NSString * path = [url.absoluteString stringByRemovingPercentEncoding];
	NSString * path2 = [path stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	path2 = [path2 stringByReplacingOccurrencesOfString:@"https://" withString:@""];
	path2 = [path2 stringByReplacingOccurrencesOfString:@":" withString:@"-"];
	path2 = [path2 stringByReplacingOccurrencesOfString:@"?" withString:@"-"];
	path2 = [path2 stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	path2 = [path2 stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	path2 = [path2 stringByAppendingString:@".cc"];
	return [_cacheDir URLByAppendingPathComponent:path2];
}

- (NSURL *) localFileURLForURL:(NSURL *) url {
	if(!url) {
		return NULL;
	}
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
	__weak UIImageView * weakSelf = self;
	dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0);
	dispatch_async(background, ^{
		NSDate * modified = [NSDate date];
		NSDictionary * attributes = @{NSFileModificationDate:modified};
		[[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:cachedURL.path error:nil];
		UIImage * image = [UIImage imageWithContentsOfFile:cachedURL.path];
		dispatch_async(dispatch_get_main_queue(), ^{
			weakSelf.image = image;
			if(completion) {
				completion(nil,image);
			}
		});
	});
}

- (NSDate *) createdDateForFileURL:(NSURL *) url {
	NSDictionary * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil];
	if(!attributes) {
		return nil;
	}
	return attributes[NSFileCreationDate];
}

- (void) writeData:(NSData *) data toFile:(NSURL *) cachedURL {
	dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0);
	dispatch_async(background, ^{
		[data writeToFile:cachedURL.path atomically:TRUE];
	});
}

- (void) writeCacheControlData:(UIImageViewCache *) cache toFile:(NSURL *) cachedURL {
	dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0);
	dispatch_async(background, ^{
		NSData * data = [NSKeyedArchiver archivedDataWithRootObject:cache];
		[data writeToFile:cachedURL.path atomically:TRUE];
		NSDictionary * attributes = @{NSFileModificationDate:[NSDate date]};
		[[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:cachedURL.path error:nil];
	});
}

- (void) setImageForRequestWithCacheControl:(NSMutableURLRequest *) request withCompletion:(UIImageViewDiskCacheCompletion) completion; {
	if(!request.URL) {
		NSLog(@"[UIImageView+DiskCache] WARNING: request.URL was NULL");
		completion([NSError errorWithDomain:UIImageViewDiskCacheErrorDomain code:UIImageViewDiskCacheErrorNilURL userInfo:@{NSLocalizedDescriptionKey:@"request.URL is nil"}],nil);
	}
	
	//ignore built in cache from networking code. we handle ourselves.
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
	NSURL * cacheInfoFile = [self localCacheControlFileURLForURL:request.URL];
	NSURL * cachedImageURL = [self localFileURLForURL:request.URL];
	UIImageViewCache * cached = [[UIImageViewCache alloc] init];
	
	//see if cache info file exists.
	if([[NSFileManager defaultManager] fileExistsAtPath:cacheInfoFile.path]) {
		
		cached = [NSKeyedUnarchiver unarchiveObjectWithFile:cacheInfoFile.path];
		
		//set image if it's available. regardless if a reload happens below. Want an image shown as soon as possible.
		BOOL setFile = FALSE;
		if([[NSFileManager defaultManager] fileExistsAtPath:cachedImageURL.path]) {
			setFile = TRUE;
			[self setImageInBackground:cachedImageURL completion:nil];
		}
		
		//check max age
		NSDate * now = [NSDate date];
		NSDate * createdDate = [self createdDateForFileURL:cachedImageURL];
		NSTimeInterval diff = [now timeIntervalSinceDate:createdDate];
		
		//cache is still valid, don't reload
		if(setFile && cached.maxage > 0 && diff < cached.maxage) {
			return;
		}
	}
	
	//check if there's an etag from the server available.
	if(cached.etag) {
		[request setValue:cached.etag forHTTPHeaderField:@"If-None-Match"];
		
		if(cached.maxage == 0) {
			NSLog(@"[UIImageView+DiskCache] WARNING: Image response ETag is set but no Cache-Control is available. "
				  @"Image requests will always be sent, the response may or may not be 304."
				  @"Add Cache-Control policies to the server to correctly have content expire locally.");
		}
	}
	
	NSURLSessionDataTask * task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if(error) {
				completion(error,nil);
				return;
			}
			
			NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
			NSDictionary * headers = [httpResponse allHeaderFields];
			
			if(httpResponse.statusCode == 304) { //304 Not Modified. Use Cache.
				[self setImageInBackground:cachedImageURL completion:completion];
				return;
			}
			
			if(httpResponse.statusCode != 200) {
				NSString * message = [NSString stringWithFormat:@"Invalid image cache response %li",(long)httpResponse.statusCode];
				completion([NSError errorWithDomain:UIImageViewDiskCacheErrorDomain code:UIImageViewDiskCacheErrorResponseCode userInfo:@{NSLocalizedDescriptionKey:message}],nil);
				return;
			}
			
			NSString * contentType = headers[@"Content-Type"];
			if(![self acceptedContentType:contentType]) {
				completion([NSError errorWithDomain:UIImageViewDiskCacheErrorDomain code:UIImageViewDiskCacheErrorContentType userInfo:@{NSLocalizedDescriptionKey:@"Response was not an image"}],nil);
				return;
			}
			
			if(headers[@"ETag"]) {
				cached.etag = headers[@"ETag"];
				
				if(!headers[@"Cache-Control"]) {
					NSLog(@"[UIImageView+DiskCache] WARNING: Image response ETag is set but no Cache-Control is available. "
						  @"Image requests will always be sent, the response may or may not be 304."
						  @"Add Cache-Control policies to the server to correctly have content expire locally.");
				}
			}
			
			if(headers[@"Cache-Control"]) {
				NSString * control = headers[@"Cache-Control"];
				NSScanner * scanner = [[NSScanner alloc] initWithString:control];
				NSString * prelim = nil;
				[scanner scanUpToString:@"=" intoString:&prelim];
				[scanner scanString:@"=" intoString:nil];
				double maxage = -1;
				[scanner scanDouble:&maxage];
				if(maxage > -1) {
					cached.maxage = (NSTimeInterval)maxage;
				}
			}
			
			self.image = [UIImage imageWithData:data];
			[self writeData:data toFile:cachedImageURL];
			[self writeCacheControlData:cached toFile:cacheInfoFile];
			completion(nil,self.image);
		});
	}];
	
	[task resume];
}

- (void) setImageForRequest:(NSURLRequest *) request withCompletion:(UIImageViewDiskCacheCompletion) completion {
	
	if(!request.URL) {
		NSLog(@"[UIImageView+DiskCache] WARNING: request.URL was NULL");
		completion([NSError errorWithDomain:UIImageViewDiskCacheErrorDomain code:UIImageViewDiskCacheErrorNilURL userInfo:@{NSLocalizedDescriptionKey:@"request.URL is nil"}],nil);
	}
	
	NSURL * cachedURL = [self localFileURLForURL:request.URL];
	if([[NSFileManager defaultManager] fileExistsAtPath:cachedURL.path]) {
		[self setImageInBackground:cachedURL completion:completion];
		return;
	}
	
	NSLog(@"[UIImageView+DiskCache] cache miss for url: %@",request.URL);
	
	__weak UIImageView * weakSelf = self;
	
	NSURLSessionDataTask * imageTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if(error) {
				completion(error,nil);
				return;
			}
			
			NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
			if(httpResponse.statusCode != 200) {
				NSString * message = [NSString stringWithFormat:@"Invalid image cache response %li",(long)httpResponse.statusCode];
				completion([NSError errorWithDomain:UIImageViewDiskCacheErrorDomain code:UIImageViewDiskCacheErrorResponseCode userInfo:@{NSLocalizedDescriptionKey:message}],nil);
				return;
			}
			
			NSString * contentType = [[httpResponse allHeaderFields] objectForKey:@"Content-Type"];
			if(![weakSelf acceptedContentType:contentType]) {
				completion([NSError errorWithDomain:UIImageViewDiskCacheErrorDomain code:UIImageViewDiskCacheErrorContentType userInfo:@{NSLocalizedDescriptionKey:@"Response was not an image"}],nil);
				return;
			}
			
			if(data) {
				weakSelf.image = [UIImage imageWithData:data];
				[weakSelf writeData:data toFile:cachedURL];
				completion(nil,weakSelf.image);
			}
		});
	}];
	
	[imageTask resume];
}

- (void) setImageForURLWithCacheControl:(NSURL *) url withCompletion:(UIImageViewDiskCacheCompletion) completion; {
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
	[self setImageForRequestWithCacheControl:request withCompletion:completion];
}

- (void) setImageForURLWithCacheControlAndDefaultAuthBasic:(NSURL *) url withCompletion:(UIImageViewDiskCacheCompletion) completion; {
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
	[request setValue:_auth forHTTPHeaderField:@"Authorization"];
	[self setImageForRequestWithCacheControl:request withCompletion:completion];
}

- (void) setImageForURLWithCacheControl:(NSURL *) url authBasicUsername:(NSString *) username password:(NSString *) password withCompletion:(UIImageViewDiskCacheCompletion) completion; {
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
	NSString * authString = [NSString stringWithFormat:@"%@:%@",username,password];
	NSData * authData = [authString dataUsingEncoding:NSUTF8StringEncoding];
	NSString * encoded = [authData base64EncodedStringWithOptions:0];
	NSString * headerValue = [NSString stringWithFormat:@"Basic %@",encoded];
	[request setValue:headerValue forHTTPHeaderField:@"Authorization"];
	[self setImageForRequestWithCacheControl:request withCompletion:completion];
}

- (void) setImageForURL:(NSURL *) url withCompletion:(UIImageViewDiskCacheCompletion) completion; {
	NSURLRequest * request = [NSURLRequest requestWithURL:url];
	[self setImageForRequest:request withCompletion:completion];
}

- (void) setImageForURL:(NSURL *) url authBasicWithUsername:(NSString *) username password:(NSString *) password withCompletion:(UIImageViewDiskCacheCompletion)completion; {
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
	NSString * authString = [NSString stringWithFormat:@"%@:%@",username,password];
	NSData * authData = [authString dataUsingEncoding:NSUTF8StringEncoding];
	NSString * encoded = [authData base64EncodedStringWithOptions:0];
	NSString * headerValue = [NSString stringWithFormat:@"Basic %@",encoded];
	[request setValue:headerValue forHTTPHeaderField:@"Authorization"];
	[self setImageForRequest:request withCompletion:completion];
}

- (void) setImageWithDefaultAuthBasicForURL:(NSURL *) url withCompletion:(UIImageViewDiskCacheCompletion) completion; {
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
	[request setValue:_auth forHTTPHeaderField:@"Authorization"];
	[self setImageForRequest:request withCompletion:completion];
}

@end

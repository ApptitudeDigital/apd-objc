
#import <Foundation/Foundation.h>

@interface NSString (Additions)

+ (NSString *) UTF8StringWithDataAndLatin1MacOSFallbacks:(NSData *) data;
- (NSString *) stringByTrimmingNewlines;
- (NSString *) stringByTrimmingNewlinesAndWhitespace;
- (NSString *) stringByTrimmingWhitespace;
- (BOOL) isValidEmail;
- (BOOL) isValidURL;
- (BOOL) isEmpty;

@end

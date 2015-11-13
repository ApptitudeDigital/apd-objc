
#import "NSMutableURLRequest+Additions.h"

@implementation NSMutableURLRequest (Additions)

- (void) setAuthBasicHeaderUsername:(NSString *) username password:(NSString *) password; {
	NSString * auth = [NSString stringWithFormat:@"%@:%@",username,password];
	NSData * data = [auth dataUsingEncoding:NSUTF8StringEncoding];
	NSString * base64 = [data base64EncodedStringWithOptions:0];
	NSString * authString = [NSString stringWithFormat:@"Basic %@",base64];
	[self setValue:authString forHTTPHeaderField:@"Authorization"];
}

@end

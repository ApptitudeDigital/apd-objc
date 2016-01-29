
#import "NSString+Additions.h"

@implementation NSString (Additions)

- (NSString *) stringByTrimmingNewlines; {
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (NSString *) stringByTrimmingNewlinesAndWhitespace; {
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *) stringByTrimmingWhitespace; {
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

+ (NSString *) UTF8StringWithDataAndLatin1MacOSFallbacks:(NSData *) data; {
	//https://mikeash.com/pyblog/friday-qa-2010-02-19-character-encodings.html
	NSString * s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if(!s) {
		s = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
	}
	if(!s) {
		s = [[NSString alloc] initWithData:data encoding:NSMacOSRomanStringEncoding];
	}
	return s;
}

- (BOOL) isValidEmail {
	NSString * pattern = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
	NSRegularExpression * regex = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:nil];
	NSArray * matches = [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)];
	if(matches.count < 1) {
		return FALSE;
	}
	return TRUE;
}

- (BOOL) isEmpty{
	return [self stringByReplacingOccurrencesOfString:@" " withString:@""].length < 1;
}

- (BOOL) isValidURL; {
	//(https?|ftp):\\/\\/
	NSString * pattern = @"^([a-zA-Z0-9.-]+(:[a-zA-Z0-9.&%$-]+)*@)*((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]?)(\\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){3}|([a-zA-Z0-9-]+\\.)*[a-zA-Z0-9-]+\\.(com|edu|gov|int|mil|net|org|biz|arpa|info|name|pro|aero|coop|museum|[a-zA-Z]{2}))(:[0-9]+)*(\\/($|[a-zA-Z0-9.,?'\\+&%$#=~_-]+))*$";
	NSRegularExpression * regex = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:nil];
	NSArray * matches = [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)];
	if(matches.count < 1) {
		return FALSE;
	}
	return TRUE;
}

@end

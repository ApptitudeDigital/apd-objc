
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

@end

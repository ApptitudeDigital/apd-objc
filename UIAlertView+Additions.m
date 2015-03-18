
#import "UIAlertView+Additions.h"

@implementation UIAlertView (Additions)

- (id) initWithMessage:(NSString *) message; {
	self = [super init];
	self.message = message;
	return self;
}

- (id) initWithTitle:(NSString *) title message:(NSString *) message; {
	self = [super init];
	self.message = message;
	self.title = title;
	return self;
}

@end

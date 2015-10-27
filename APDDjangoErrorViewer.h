#import <UIKit/UIKit.h>

@interface APDDjangoErrorViewer : UIViewController{
	BOOL _hasShown;
	NSURL *_url;
	NSString *_errorData;
}

@property (weak) IBOutlet UIWebView *webView;

- (void)showErrorData:(NSString *)errorData forURL:(NSURL *)url;

@end

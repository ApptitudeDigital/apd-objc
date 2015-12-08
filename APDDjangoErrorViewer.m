#import "APDDjangoErrorViewer.h"

@implementation APDDjangoErrorViewer


- (IBAction)close:(UIButton *)sender{
	if(self.parentViewController){
		[self.parentViewController dismissViewControllerAnimated:YES completion:^{}];
		return;
	}
	[self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)showErrorData:(NSString *)errorData forURL:(NSURL *)url{
	_url = url;
	_errorData = errorData;
	[self updateWebView];
}

- (void)updateWebView{
	if(!self.webView){
		return;
	}
	[self.webView loadHTMLString:_errorData baseURL:_url];
}

@end

#import <UIKit/UIKit.h>

@interface APDImageSequencePlayer : UIImageView{
	NSTimer *_playTimer;
	
}

@property NSURL *fileDirectory;
@property NSString *fileName;
@property CGFloat fps;
@property (readonly) NSArray *fileURLs;
@property (nonatomic) CGFloat position;
@property BOOL repeats;

- (id)initWithDirectory:(NSURL *)directory fileName:(NSString *)fileName andFPS:(CGFloat)fps;
- (CGFloat)duration;
- (void)play;
- (void)pause;
- (void)stop;
- (void)refresh;




@end

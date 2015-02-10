#import <UIKit/UIKit.h>

@interface UIImage (Additions)

- (UIColor *)colorAtPosition:(CGPoint)position;
- (UIImage *) imageByCroppingImage:(UIImage *) image toSize:(CGSize) size;

@end

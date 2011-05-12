#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface openFrameworksViewController : UIViewController
{
	EAGLContext *context;
	GLuint program;

	BOOL animating;
	NSInteger animationFrameInterval;
	CADisplayLink *displayLink;

	NSMutableDictionary *activeTouches;

@protected
	int mouseX, mouseY;
}

@property (readonly, nonatomic, getter = isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;

- (void)startAnimation;
- (void)stopAnimation;

- (void)setup;
- (void)update;
- (void)draw;
- (void)exit;
- (void)windowResized:(CGSize)size;

- (void)touchDown:(CGPoint)point touchIndex:(int)touchIndex;
- (void)touchMoved:(CGPoint)point touchIndex:(int)touchIndex;
- (void)touchUp:(CGPoint)point touchIndex:(int)touchIndex;
- (void)touchDoubleTap:(CGPoint)point touchIndex:(int)touchIndex;

- (void)audioReceived:(float*)input bufferSize:(int)bufferSize numChannels:(int)numChannels;
- (void)audioRequested:(float*)output bufferSize:(int)bufferSize numChannels:(int)numChannels;

@end
#import <UIKit/UIKit.h>

#import <OpenGLES/EAGL.h>

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "MyEAGLView.h"

@interface ofxUIViewController : UIViewController {
    EAGLContext *context;
    GLuint program;
    
    BOOL animating;
    NSInteger animationFrameInterval;
    CADisplayLink *displayLink;
	
	MyEAGLView *glView;
	
	NSMutableDictionary *activeTouches;
	
@protected
	int mouseX, mouseY;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;

- (void)setup;
- (void)update;
- (void)draw;

- (void)touchDown:(CGPoint)point touchIndex:(int)touchIndex;
- (void)touchMoved:(CGPoint)point touchIndex:(int)touchIndex;
- (void)touchUp:(CGPoint)point touchIndex:(int)touchIndex;
- (void)touchDoubleTap:(CGPoint)point touchIndex:(int)touchIndex;

@end

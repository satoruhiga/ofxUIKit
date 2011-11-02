#import <QuartzCore/QuartzCore.h>

#include "ofMain.h"
#include "ofAppBaseWindow.h"

#import "ofxUIViewController.h"

class ofxiPhoneWindowProxy : public ofAppBaseWindow
{
public:
	
	UIView *view;
	
	ofxiPhoneWindowProxy(UIView *view_)
	{
		view = view_;
	}
	
	int getWidth()
	{
		
		return view.bounds.size.width;
	}
	
	int getHeight()
	{
		return view.bounds.size.height;
	}
};

static ofxiPhoneWindowProxy *window_proxy;

@interface ofxUIViewController ()
@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, retain) MyEAGLView *glView;
@property (nonatomic, assign) CADisplayLink *displayLink;
- (void)startAnimation;
- (void)stopAnimation;
@end

@implementation ofxUIViewController

@synthesize animating, context, displayLink, glView;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	activeTouches = [[NSMutableDictionary alloc] init];
	
	self.context = [[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1] autorelease];
    
    if (!self.context)
        NSLog(@"Failed to create ES context");
    else if (![EAGLContext setCurrentContext:self.context])
        NSLog(@"Failed to set ES context current");
	
	self.glView = [[[MyEAGLView alloc] initWithFrame:self.view.bounds] autorelease];
	[self.view addSubview:self.glView];
	self.glView.autoresizingMask = 0xFF;
	
    [self.glView setContext:context];
    [self.glView setFramebuffer];
    
    animating = FALSE;
    animationFrameInterval = 1;
    self.displayLink = nil;
	
	// setup oF
	window_proxy = new ofxiPhoneWindowProxy(self.view);
	ofSetupOpenGL(window_proxy, self.view.frame.size.width, self.view.frame.size.height, OF_FULLSCREEN);
	ofSetCurrentRenderer(ofPtr<ofBaseRenderer>(new ofGLRenderer()));
	
	ofSetDataPathRoot([[[NSBundle mainBundle] resourcePath] UTF8String] + string("/data/"));
	
	[self setup];
}

- (void)dealloc
{
	// Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
    
    [context release];
	[activeTouches release];
    
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self startAnimation];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopAnimation];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
    // Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	self.context = nil;	
}

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    if (frameInterval >= 1)
    {
        animationFrameInterval = frameInterval;
        
        if (animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
    if (!animating)
    {
		if (CGRectEqualToRect(self.view.frame, self.glView.bounds))
		{
			self.glView.frame = self.view.bounds;
		}
		
        CADisplayLink *aDisplayLink = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(drawFrame)];
        [aDisplayLink setFrameInterval:animationFrameInterval];
        [aDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.displayLink = aDisplayLink;
        
        animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating)
    {
        [self.displayLink invalidate];
        self.displayLink = nil;
        animating = FALSE;
    }
}

- (void)drawFrame
{
	[(MyEAGLView *)self.glView setFramebuffer];
	[self update];
	
	float * bgPtr = ofBgColorPtr();
	bool bClearAuto = ofbClearBg();
	
	if (bClearAuto == true)
	{
		glClearColor(bgPtr[0], bgPtr[1], bgPtr[2], bgPtr[3]);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	}
	
	ofSetupScreen();
	
	[self draw];
	[(MyEAGLView *)self.glView presentFramebuffer];
}

- (void)setup
{
}

- (void)update
{
}

- (void)draw
{
}

#pragma mark touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[(MyEAGLView *)self.view setFramebuffer];
	
	for (UITouch *i in touches)
	{
		int touchIndex = 0;
		while ([[activeTouches allValues] containsObject:[NSNumber numberWithInt:touchIndex]])
		{
			touchIndex++;
		}
		
		[activeTouches setObject:[NSNumber numberWithInt:touchIndex] forKey:[NSValue valueWithPointer:i]];
		
		CGPoint p = [i locationInView:self.view];
		
		mouseX = p.x;
		mouseY = p.y;
		
		if (i.tapCount == 2) [self touchDoubleTap:p touchIndex:touchIndex];
		[self touchDown:p touchIndex:touchIndex];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[(MyEAGLView *)self.view setFramebuffer];
	
	for (UITouch *i in touches)
	{
		int touchIndex = [[activeTouches objectForKey:[NSValue valueWithPointer:i]] intValue];
		
		CGPoint p = [i locationInView:self.view];
		
		mouseX = p.x;
		mouseY = p.y;
		
		[self touchMoved:p touchIndex:touchIndex];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[(MyEAGLView *)self.view setFramebuffer];
	
	for (UITouch *i in touches)
	{
		int touchIndex = [[activeTouches objectForKey:[NSValue valueWithPointer:i]] intValue];
		[activeTouches removeObjectForKey:[NSValue valueWithPointer:i]];
		
		CGPoint p = [i locationInView:self.view];
		
		mouseX = p.x;
		mouseY = p.y;
		
		[self touchUp:p touchIndex:touchIndex];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesEnded:touches withEvent:event];
}

@end

#import <QuartzCore/QuartzCore.h>

#include "ofMain.h"

#import "openFrameworksViewController.h"
#import "ofEAGLView.h"

static CGSize windowSize;

int ofGetWidth()
{
	return windowSize.width;
}

int ofGetHeight()
{
	return windowSize.height;
}

@interface openFrameworksViewController ()
@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, assign) CADisplayLink *displayLink;
@end

@implementation openFrameworksViewController

@synthesize animating, context, displayLink;

- (void)dealloc
{
	[super dealloc];
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	activeTouches = [[NSMutableDictionary alloc] init];
	
	if ([self.view class] != [ofEAGLView class])
	{
		ofLog(OF_LOG_WARNING, "self.view is not class of ofEAGLView");
		self.view = [[[ofEAGLView alloc] init] autorelease];
	}

	EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];

	if (!aContext)
		NSLog(@"Failed to create ES context");
	else if (![EAGLContext setCurrentContext:aContext])
		NSLog(@"Failed to set ES context current");

	self.context = aContext;
	[aContext release];

	[(ofEAGLView *)self.view setContext:context];

	animating = FALSE;
	animationFrameInterval = 1;
	self.displayLink = nil;

	[(ofEAGLView *)self.view setFramebuffer];

	[self setup];

	[(ofEAGLView *)self.view presentFramebuffer];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	if ([EAGLContext currentContext] == context)
		[EAGLContext setCurrentContext:nil];
	
	self.context = nil;
	
	[(ofEAGLView *)self.view setFramebuffer];
	
	[self exit];
	
	[(ofEAGLView *)self.view presentFramebuffer];
	
	[activeTouches release];
	
	[(ofEAGLView *)self.view setFramebuffer];
	
	[self exit];
	
	[(ofEAGLView *)self.view presentFramebuffer];
	
	// Tear down context.
	if ([EAGLContext currentContext] == context)
		[EAGLContext setCurrentContext:nil];
	
	[context release];
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
	[(ofEAGLView *)self.view setFramebuffer];

	CGSize newSize = self.view.bounds.size;

	if (windowSize.width != newSize.width || windowSize.height != newSize.height)
	{
		[self windowResized:newSize];
		windowSize = newSize;
	}

	float *bgPtr = ofBgColorPtr();
	bool bClearAuto = ofbClearBg();

	glViewport(0, 0, windowSize.width, windowSize.height);

	if (bClearAuto == true)
	{
		glClearColor(bgPtr[0], bgPtr[1], bgPtr[2], bgPtr[3]);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	}

	ofSetupScreen();

	[self update];

	glPushMatrix();
	[self draw];
	glPopMatrix();

	[(ofEAGLView *)self.view presentFramebuffer];
}

#pragma mark touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[(ofEAGLView *)self.view setFramebuffer];

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
	[(ofEAGLView *)self.view setFramebuffer];

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
	[(ofEAGLView *)self.view setFramebuffer];

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

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark oF-like interface

- (void)setup
{
}

- (void)update
{
}

- (void)draw
{
}

- (void)exit
{
}

- (void)windowResized:(CGSize)size
{
}

- (void)touchDown:(CGPoint)point touchIndex:(int)touchIndex
{
}

- (void)touchMoved:(CGPoint)point touchIndex:(int)touchIndex
{
}

- (void)touchUp:(CGPoint)point touchIndex:(int)touchIndex
{
}

- (void)touchDoubleTap:(CGPoint)point touchIndex:(int)touchIndex
{
}

- (void)audioReceived:(float*)input bufferSize:(int)bufferSize numChannels:(int)numChannels
{
}

- (void)audioRequested:(float*)output bufferSize:(int)bufferSize numChannels:(int)numChannels
{
}

@end
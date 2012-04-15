//
//  FractalView.m
//  Fractal
//
//  Created by Mario Hros on 24.1.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FractalView.h"

@implementation FractalView
@synthesize m_sldIter, m_lblInfo, m_btnCol, m_btnDim;

// vertex positions of quad
static const GLfloat s_quadVertices[] = {
    -1.0f, -1.0f, 0.0f,
    1.0f, -1.0f, 0.0f,
    1.0f, 1.0f, 0.0f,
    -1.0f, 1.0f, 0.0f
};

// texture coords for quad
static const GLfloat s_quadCoords[] = {
    0.0f,			0.0f,
    1.0f/512*320,	0.0f,
    1.0f/512*320,	1.0f/512*480,
    0.0f,			1.0f/512*480
};


// OpenGL support method
+ (Class)layerClass {
	return [CAEAGLLayer class];
}


- (void)awakeFromNib {
		
	printf("Initializing\n");
	
	// create timer
	m_timer = [NSTimer scheduledTimerWithTimeInterval:0 
											   target:self selector:@selector(nextFrame) 
											 userInfo:nil 
											  repeats:YES];
	// fps and info timer
	m_frametimer = [NSTimer scheduledTimerWithTimeInterval:1 
													target:self selector:@selector(frameInfo) 
												  userInfo:nil 
												   repeats:YES];
	m_frames = 0;
	
	// prepare layer 
	CAEAGLLayer  *eaglLayer = (CAEAGLLayer*)self.layer;
	eaglLayer.opaque = YES;
	eaglLayer.drawableProperties =	[NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithBool:NO], 
									 kEAGLDrawablePropertyRetainedBacking,
									 kEAGLColorFormatRGBA8, 
									 kEAGLDrawablePropertyColorFormat,
									 nil]; 
	
	// create OpenGL context
	m_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1]; 
	if(!m_context) {
		printf("ERROR! Failed to create render context!\n");
		exit(-1);
	}
	
	if(![EAGLContext setCurrentContext:m_context]) {
		printf("ERROR! Failed to set current render context!\n");
		exit(-1);
	}
	
	// create render buffer
	glGenRenderbuffersOES(1, &m_renderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, m_renderbuffer);
	
	// create render buffer storage
	if(![m_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)eaglLayer]) {
		glDeleteRenderbuffersOES(1, &m_renderbuffer);
		
		printf("ERROR! Failed to create render buffer storage!\n");
		exit(-1);
	}
	
	// create frame buffer
	glGenFramebuffersOES(1, &m_framebuffer);
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, m_framebuffer);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, 
								 GL_RENDERBUFFER_OES, m_renderbuffer);
	
	
	CGSize newSize = [eaglLayer bounds].size;
	glViewport(0, 0, newSize.width, newSize.height);

	// bind render buffer
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, m_renderbuffer);
	
	// create render target texture
	glGenTextures(1, &m_rendertexture);
	glBindTexture(GL_TEXTURE_2D, m_rendertexture);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);	
	
	glDisable(GL_LIGHTING);
	glDisable(GL_BLEND);
	glDisable( GL_MULTISAMPLE );
	glEnable(GL_TEXTURE_2D);
	
	// apply render states in advance
	glBindTexture( GL_TEXTURE_2D, m_rendertexture );

	glVertexPointer(3, GL_FLOAT, 0, s_quadVertices);
	glEnableClientState(GL_VERTEX_ARRAY);

	glTexCoordPointer(2, GL_FLOAT, 0, s_quadCoords);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	// create buffer for pixel data
	m_bufferSize = 512;
	m_buffer = malloc(m_bufferSize*m_bufferSize*4);
	
	// default values
	m_offsetX = -1.8f;
	m_offsetY = -1.1f;
	m_sizeX = m_sizeY = 2;
	m_moving = false;
	m_coloring = m_diming = true;
	
	self.multipleTouchEnabled = YES;
	
	printf("Initialization done\n");
}


__inline__ void setPixel(unsigned char* buffer, int x, int y, 
						 unsigned char r, unsigned char g, unsigned char b)
{
	// clip for sure...
	if (x<0) return;
	else if (x>320) return;
	else if (y<0) return;
	else if (y>480) return;
	
	
	// map to pixel data
	unsigned char* pr = buffer + (512*(480-y)+x)*4;
	unsigned char* pg = pr+1;
	unsigned char* pb = pr+2;
	//unsigned char* pa = pr+3;
	
	//*pa = 255;
	*pr = r;
	*pg = g;
	*pb = b;
}

void quadratic(unsigned char* buffer, float offsetX, float offsetY, float sizeX, float sizeY, 
			   float x, float y, int maxIter, int iter, bool coloring, bool dimming)
{	
	const float a = -0.6f;
	const float b = -0.4f;
	const float c = -0.4f;
	const float d = -0.8f;
	const float e = 0.7f;
	const float f = 0.3f;
	const float g = -0.4f;
	const float h = 0.4f;
	const float i = 0.5f;
	const float j = 0.5f;
	const float k = 0.8f;
	const float l = 0.1f;
	
	// here the new X and Y are computed (four iterations for performance reasons)
	float nx1 = a + b*x + c*x*x + d*x*y + e*y + f*y*y;
	float ny1 = g + h*x + i*x*x + j*x*y + k*y + l*y*y;
	float nx2 = a + b*nx1 + c*nx1*nx1 + d*nx1*ny1 + e*ny1 + f*ny1*ny1;
	float ny2 = g + h*nx1 + i*nx1*nx1 + j*nx1*ny1 + k*ny1 + l*ny1*ny1;	
	float nx3 = a + b*nx2 + c*nx2*nx2 + d*nx2*ny2 + e*ny2 + f*ny2*ny2;
	float ny3 = g + h*nx2 + i*nx2*nx2 + j*nx2*ny2 + k*ny2 + l*ny2*ny2;	
	float nx4 = a + b*nx3 + c*nx3*nx3 + d*nx3*ny3 + e*ny3 + f*ny3*ny3;
	float ny4 = g + h*nx3 + i*nx3*nx3 + j*nx3*ny3 + k*ny3 + l*ny3*ny3;	
	
	// screen coordinates
	int scrX1 = (nx1-offsetX)/sizeX*320;
	int scrX2 = (nx2-offsetX)/sizeX*320;
	int scrX3 = (nx3-offsetX)/sizeX*320;
	int scrX4 = (nx4-offsetX)/sizeX*320;
	int scrY1 = (ny1-offsetY)/sizeY*480;
	int scrY2 = (ny2-offsetY)/sizeY*480;
	int scrY3 = (ny3-offsetY)/sizeY*480;
	int scrY4 = (ny4-offsetY)/sizeY*480;
	
	// only if the new coordinates are inside view..
	bool insideView = scrX4 > 0 && scrY4 > 0 && scrX4 < 320 && scrY4 < 480;
	
	// render computed points
	if (insideView || sizeX<1.3f) 
	{
		// color dim
		float dim;
		if (dimming)
			dim = 1.0f/maxIter*iter;
		else {
			dim = 1;
		}
		
		if (!coloring) 
		{
			if (dimming) 
			{
				setPixel(buffer, scrX1, scrY1, 0, dim*100.0f, dim*100.0f);
				setPixel(buffer, scrX2, scrY2, 0, dim*150.0f, dim*150.0f);
				setPixel(buffer, scrX3, scrY3, 0, dim*200.0f, dim*200.0f);
				setPixel(buffer, scrX4, scrY4, 0, dim*250.0f, dim*250.0f);
			}
			else 
			{
				setPixel(buffer, scrX1, scrY1, 0, 255, 255);
				setPixel(buffer, scrX2, scrY2, 0, 255, 255);
				setPixel(buffer, scrX3, scrY3, 0, 255, 255);
				setPixel(buffer, scrX4, scrY4, 0, 255, 255);
			}

		}
		else {
			// colors by coord deltas
			float cg1 = dim*100*fabsf(x  -nx1);
			float cg2 = dim*150*fabsf(nx1-nx2);
			float cg3 = dim*200*fabsf(nx2-nx3);
			float cg4 = dim*250*fabsf(nx3-nx4);
			float cb1 = dim*100*fabsf(y  -ny1);
			float cb2 = dim*150*fabsf(ny1-ny2);
			float cb3 = dim*200*fabsf(ny2-ny3);
			float cb4 = dim*250*fabsf(ny3-ny4);
			
			// colored pixels
			setPixel(buffer, scrX1, scrY1, dim*100.0f, MIN(255,cg1), MIN(255,cb1));
			setPixel(buffer, scrX2, scrY2, dim*150.0f, MIN(255,cg2), MIN(255,cb2));
			setPixel(buffer, scrX3, scrY3, dim*200.0f, MIN(255,cg3), MIN(255,cb3));
			setPixel(buffer, scrX4, scrY4, dim*250.0f, MIN(255,cg4), MIN(255,cb4));
		}
	}
	
	// next iteration...
	if (iter < maxIter && (iter<5 || insideView || sizeX<1.3f) )
		quadratic(buffer, offsetX, offsetY, sizeX, sizeY, nx4, ny4, maxIter, iter+4, coloring, dimming);
}

__inline__ void renderFractal(unsigned char* buffer, float offsetX, float offsetY, float sizeX, float sizeY, 
							  int maxIter, int step, bool color, bool dim) 
{
	const float sizeDivWid = 2.0f/320;
	const float sizeDivHei = 2.0f/480;
	
	for (register int x = 0; x<320; x+=step)
	{
		for (register int y = 0; y<480; y+=2)
		{
			// to fractal coords
			float fx = -1 + sizeDivWid * x;
			float fy = 0 + sizeDivHei * y;
			
			quadratic(buffer, offsetX, offsetY, sizeX, sizeY, fx, fy, maxIter, 0, color, dim);
		}
	}
}

-(void)frameInfo {
	
	int maxIter = m_sldIter.value;
	maxIter -= maxIter%4;
	
	m_lblInfo.text = [NSString stringWithFormat:@"FPS: %d  Iters %d  Offset [%.1f, %.1f]  Size [%.1f, %.1f]", 
					  m_frames, maxIter, m_offsetX, m_offsetY, m_sizeX, m_sizeY];
	
	m_frames = 0;
}

-(void)nextFrame {
	
	// frame counting
	m_frames++;
	
	// clear
	//glClearColor(1, 0, 0, 1);
	//glClear (GL_COLOR_BUFFER_BIT);
	
	// clear buffer
	memset(m_buffer, 0, m_bufferSize*m_bufferSize*4);
	
	// get max iteration count
	int maxIter = m_sldIter.value;
	maxIter -= maxIter%4; // align to multiply-of-4
	
	// render fractal
	renderFractal(m_buffer, m_offsetX, m_offsetY, m_sizeX, m_sizeY, maxIter, m_moving?4:2, m_coloring, m_diming);
	
	// update texture (already bound at startup)
    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, m_bufferSize, m_bufferSize, 0, GL_RGBA, GL_UNSIGNED_BYTE, m_buffer );
	
	// draw that!
	glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
	
	
	// present render buffer
	if(![m_context presentRenderbuffer:GL_RENDERBUFFER_OES])
		printf("ERROR! Failed to present renderbuffer!\n");
}


- (void)dealloc {
	
	free(m_buffer);
	
	[m_sldIter release];
	[m_lblInfo release];
	
	[m_btnCol release];
	[m_btnDim release];
	
    [super dealloc];
}


#pragma mark === User Interaction ===

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{	
	m_moving = true;
	
	NSEnumerator *enumerator = [touches objectEnumerator];
	
	UITouch *touch; int i=0;
	while ((touch = [enumerator nextObject])) 
	{
		if (m_firstFinger == nil) // first finger - movement
		{
			CGPoint pnt = [touch locationInView:self];
			m_pntStart = pnt;
			
			m_firstFinger = touch;
		}
		else if (m_secondFinger == nil) // second finger - scale
		{
			CGPoint pnt = [touch locationInView:self];
			
			float lenX =  m_pntStart.x-pnt.x;
			float lenY =  m_pntStart.y-pnt.y;
			
			m_fingerDist = sqrt(lenX*lenX + lenY*lenY);
			
			m_secondFinger = touch;
		}
		i++;
	}
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	m_moving = true;
	
	NSEnumerator *enumerator = [touches objectEnumerator];
	
	UITouch *touch; int i=0;
	while ((touch = [enumerator nextObject]))
	{
		if (touch == m_firstFinger) // first finger - movement
		{
			CGPoint pnt = [touch locationInView:self];
			
			int lenX =  m_pntStart.x-pnt.x;
			int lenY =  m_pntStart.y-pnt.y;
			
			m_offsetX += lenX*0.004f*m_sizeX;
			m_offsetY += lenY*0.004f*m_sizeY;
			
			m_pntStart = pnt;
		}
		else if (touch == m_secondFinger) // second finger - scale
		{
			CGPoint pnt = [touch locationInView:self];
			
			int lenX =  m_pntStart.x-pnt.x;
			int lenY =  m_pntStart.y-pnt.y;
			
			float actDist = sqrt(lenX*lenX + lenY*lenY);
			float delta = actDist-m_fingerDist;
			
			m_sizeX -= delta*0.009f;
			m_sizeY -= delta*0.009f;		
			
			// clamp size
			m_sizeX = MAX( 0.2f, MIN(3, m_sizeX) );
			m_sizeY = MAX( 0.2f, MIN(3, m_sizeY) );
			
			m_fingerDist = actDist;
		}
		i++;
		
		
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	m_moving = false;
	
	NSEnumerator *enumerator = [touches objectEnumerator];
	
	// when the first finder was released, use second one as the first
	UITouch *touch;
	while ((touch = [enumerator nextObject]))
		if (touch == m_secondFinger)
		{
			if (m_firstFinger == m_secondFinger)
				m_firstFinger = nil;
			m_secondFinger = nil;
		}
		else if (touch == m_firstFinger)
			m_firstFinger = m_secondFinger;
}

-(IBAction)colorToggle { 
	m_coloring = !m_coloring;
	[m_btnCol setTitle:m_coloring?@"Color On":@"Color Off" forState:UIControlStateNormal];
}
-(IBAction)dimToggle {
	m_diming = !m_diming;
	[m_btnDim setTitle:m_diming?@"Dim On":@"Dim Off" forState:UIControlStateNormal];
}

-(IBAction)linkTapped
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://k3a.me"]];
}



@end

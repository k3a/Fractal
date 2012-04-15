//
//  FractalView.h
//  Fractal
//
//  Created by Mario Hros on 24.1.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QuartzCore/QuartzCore.h"

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface FractalView : UIView {

	NSTimer	*		m_timer;
	
	EAGLContext*	m_context;
	GLuint			m_framebuffer;
	GLuint			m_renderbuffer;
	
	GLuint			m_rendertexture;
	unsigned char*	m_buffer;
	int				m_bufferSize;
	
	UISlider*	m_sldIter;
	UILabel*	m_lblInfo;
	UIButton*	m_btnDim;
	UIButton*	m_btnCol;
	
	// UI
	UITouch *m_firstFinger;
	UITouch *m_secondFinger;
	CGPoint m_pntStart;
	float m_fingerDist;
	float m_offsetX;
	float m_offsetY;
	float m_sizeX;
	float m_sizeY;
	bool m_moving;
	bool m_coloring;
	bool m_diming;
	
	// DEBUG
	int			m_frames;
	NSTimer	*	m_frametimer;
}

@property(nonatomic, retain) IBOutlet UISlider* m_sldIter;
@property(nonatomic, retain) IBOutlet UILabel*	m_lblInfo;
@property(nonatomic, retain) IBOutlet UIButton*	m_btnDim;
@property(nonatomic, retain) IBOutlet UIButton*	m_btnCol;

-(void)nextFrame;
-(void)frameInfo;

-(IBAction)colorToggle;
-(IBAction)dimToggle;

@end

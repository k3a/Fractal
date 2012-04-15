//
//  FractalAppDelegate.h
//  Fractal
//
//  Created by Mario Hros on 24.1.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FractalViewController;

@interface FractalAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    FractalViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet FractalViewController *viewController;

@end


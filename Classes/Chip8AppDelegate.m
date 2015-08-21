//
//  Chip8AppDelegate.m
//  Chip8
//
//  Created by Joe Wingbermuehle on 9/14/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "Chip8AppDelegate.h"
#import "MenuView.h"
#import "EAGLView.h"

@implementation Chip8AppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication*)application {

   CGRect rect = CGRectMake(0, 0, 320, 480);

   window = [[UIWindow alloc] initWithFrame:rect];

   transition_view = [[TransitionView alloc] initWithFrame:rect];
   menu_view = [[MenuView alloc] initWithFrame:rect];
   gl_view = [[EAGLView alloc] initWithFrame:rect];

   [transition_view setDelegate:menu_view];
   [transition_view addSubview:menu_view];

   [window addSubview:transition_view];
   [window bringSubviewToFront:transition_view];
   [window makeKeyAndVisible];

}

- (void)applicationWillResignActive:(UIApplication*)application {
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
}

- (void)start:(NSString*)name {
   [transition_view replace:menu_view with:gl_view];
   [gl_view start:name];
}

- (void)stop {
   [gl_view stop];
   [transition_view replace:gl_view with:menu_view];
}

- (void)dealloc {
   [window release];
   [gl_view release];
   [menu_view release];
   [transition_view release];
   [super dealloc];
}

@end


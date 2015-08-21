//
//  Chip8AppDelegate.h
//  Chip8
//
//  Created by Joe Wingbermuehle on 9/14/08.
//  Copyright Joe Wingbermuehle 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EAGLView;
@class MenuView;
@class TransitionView;

@interface Chip8AppDelegate : NSObject <UIApplicationDelegate> {
   UIWindow *window;
   EAGLView *gl_view;
   MenuView *menu_view;
   TransitionView *transition_view;
}

@property (nonatomic, retain) UIWindow *window;

- (void)start:(NSString*)name;

- (void)stop;

@end


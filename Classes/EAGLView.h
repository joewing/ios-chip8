//
//  EAGLView.h
//  Chip8
//
//  Created by Joe Wingbermuehle on 9/14/08.
//  Copyright Joe Wingbermuehle 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface EAGLView : UIView {
   
@private

   /* The pixel dimensions of the backbuffer */
   GLint backingWidth;
   GLint backingHeight;
   
   EAGLContext *context;
   
   GLuint viewRenderbuffer, viewFramebuffer;
   
   NSTimer *animation_timer;

}

- (void)start:(NSString*)name;
- (void)stop;
- (void)drawView;

@end

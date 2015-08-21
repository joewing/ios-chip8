//
//  EAGLView.m
//  Chip8
//
//  Created by Joe Wingbermuehle on 9/14/08.
//  Copyright Joe Wingbermuehle 2008. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "Chip8AppDelegate.h"
#import "EAGLView.h"
#import "ChipThread.h"
#import "interpret.h"
#import "key.h"
#import "sound.h"

#define UPDATE_HZ    60.0

static const GLubyte BLOCK_COLORS[] = {
   0, 127, 0, 255,
   0, 127, 0, 255,
   0, 127, 0, 255,
   0, 127, 0, 255
};

static int initialized = 0;

static ChipThread *chip8;

// A class extension to declare private methods
@interface EAGLView ()

- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;

- (void)loadProgram:(NSString*)name;

@end

@implementation EAGLView

+ (Class)layerClass {
   return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)rect {

   if ((self = [super initWithFrame:rect])) {

      CAEAGLLayer *layer = (CAEAGLLayer*)self.layer;

      layer.opaque = YES;
      layer.drawableProperties
         = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithBool:NO],
            kEAGLDrawablePropertyRetainedBacking,
            kEAGLColorFormatRGBA8,
            kEAGLDrawablePropertyColorFormat, nil];

      context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];

      if (!context || ![EAGLContext setCurrentContext:context]) {
         [self release];
         return nil;
      }

      should_exit = 1;
      initialized = 0;
      animation_timer = [NSTimer 
            scheduledTimerWithTimeInterval:(1.0 / UPDATE_HZ)
            target:self selector:@selector(drawView)
            userInfo:nil repeats:YES];

   }
   return self;

}

- (void)start:(NSString*)name {
   chip8 = [[ChipThread alloc] init];
   [chip8 lock];
   should_exit = 0;
   initialized = 0;
   [self loadProgram:name];
   [chip8 unlock];
}

- (void)stop {
   [chip8 lock];
   should_exit = 1;
   initialized = 1;
   [chip8 stop];
   [chip8 unlock];
   [chip8 release];
   chip8 = nil;
}

- (void)drawView {

   [chip8 lock];

   if(should_exit) {
      [chip8 unlock];
      return;
   }

   if(!initialized) {
      [EAGLContext setCurrentContext:context];
      [self destroyFramebuffer];
      [self createFramebuffer];
      [chip8 start];
   }

   UpdateTimers();

   if(ShouldUpdateScreen()) {

      [EAGLContext setCurrentContext:context];

      glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
      glViewport(0, 0, backingWidth, backingHeight);

      if(!initialized) {
         initialized = 1;
         InitializeSound();
         glEnable(GL_ALPHA_TEST);
         glAlphaFunc(GL_GREATER, 0.75);
         glMatrixMode(GL_PROJECTION);
         glLoadIdentity();
         glOrthof(0.0, 320.0, 480.0, 0.0, -1.0, 1.0);
         glMatrixMode(GL_MODELVIEW);
         glClearColor(0.0, 0.0, 0.0, 1.0);
         glEnableClientState(GL_VERTEX_ARRAY);
      }

      // Draw the screen.

      const unsigned int width = GetScreenWidth();
      const unsigned int height = GetScreenHeight();

      const float offsetx = 2.0;
      const float offsety = 2.0;
      const float scalex = (320.0 - offsetx * 2.0) / width;
      const float scaley = (240.0 - offsety * 2.0) / height;

      glClear(GL_COLOR_BUFFER_BIT);

      GLfloat vertices[2 * 4];
      vertices[0] = 0.0;
      vertices[1] = 0.0;
      vertices[2] = scalex;
      vertices[3] = 0.0;
      vertices[4] = 0.0;
      vertices[5] = scaley;
      vertices[6] = scalex;
      vertices[7] = scaley;

      glVertexPointer(2, GL_FLOAT, 0, vertices);

      glEnableClientState(GL_COLOR_ARRAY);
      glColorPointer(4, GL_UNSIGNED_BYTE, 0, BLOCK_COLORS);

      unsigned int y;
      for(y = 0; y < height; y++) {
         unsigned int x;
         for(x = 0; x < width; x++) {
            glLoadIdentity();
            glTranslatef(x * scalex + offsetx, y * scaley + offsety, 0.0);
            if(GetScreenPixel(x, y)) {
               glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            }
         }
      }
      glDisableClientState(GL_COLOR_ARRAY);

      DrawKeys();

      glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
      [context presentRenderbuffer:GL_RENDERBUFFER_OES];

   }

   [chip8 unlock];

}


- (void)layoutSubviews {
}


- (BOOL)createFramebuffer {

   glGenFramebuffersOES(1, &viewFramebuffer);
   glGenRenderbuffersOES(1, &viewRenderbuffer);

   glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
   glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
   [context renderbufferStorage:GL_RENDERBUFFER_OES
            fromDrawable:(CAEAGLLayer*)self.layer];
   glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES,
                                GL_RENDERBUFFER_OES, viewRenderbuffer);

   glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES,
                                   GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
   glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES,
                                   GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);


   if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES)
         != GL_FRAMEBUFFER_COMPLETE_OES) {
      return NO;
   }

   return YES;

}


- (void)destroyFramebuffer {

   if(viewFramebuffer) {
      glDeleteFramebuffersOES(1, &viewFramebuffer);
      viewFramebuffer = 0;
      glDeleteRenderbuffersOES(1, &viewRenderbuffer);
      viewRenderbuffer = 0;
   }
}

- (void)loadProgram:(NSString*)name {

   CFBundleRef bundle;
   CFURLRef url;

   bundle = CFBundleGetMainBundle();
   url = CFBundleCopyResourceURL(bundle, (CFStringRef)name, CFSTR("dat"), NULL);

   UInt8 path[256];
   CFURLGetFileSystemRepresentation(url, true, path, sizeof(path));
   FILE *fd = fopen((char*)path, "rb");
   if(fd) {

      char *buffer = malloc(4096);
      if(buffer) {
         size_t sz = fread(buffer, 1, 4096, fd);
         LoadProgram(buffer, sz);
         free(buffer);
      }

      fclose(fd);
   }

   CFRelease(url);

// TODO
   ClearKeys();
   AddKey(0, "1");
   AddKey(1, "2");
   AddKey(2, "3");
   AddKey(3, "C");
   AddKey(4, "4");
   AddKey(5, "5");
   AddKey(6, "6");
   AddKey(7, "D");
   AddKey(8, "7");
   AddKey(9, "8");
   AddKey(10, "9");
   AddKey(11, "E");
   AddKey(12, "A");
   AddKey(13, "0");
   AddKey(14, "B");
   AddKey(15, "F");

}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {

   UITouch *touch = [touches anyObject];
   CGPoint point = [touch locationInView:self];

   [chip8 lock];
   RegisterKeyPress(point.x, point.y);
   [chip8 unlock];

}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {

   UITouch *touch = [touches anyObject];
   CGPoint point = [touch locationInView:self];

   [chip8 lock];
   RegisterKeyPress(point.x, point.y);
   [chip8 unlock];

}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {

   UITouch *touch = [touches anyObject];
   CGPoint point = [touch locationInView:self];
   if(point.y < 480 / 2) {

      Chip8AppDelegate *d = [UIApplication sharedApplication].delegate;
      [d stop];

   } else {

      [chip8 lock];
      ReleaseKeys();
      [chip8 unlock];

   }

}

- (void)dealloc {

   [animation_timer invalidate];
   animation_timer = nil;

   [chip8 lock];
   should_exit = 1;
   [chip8 stop];
   [chip8 unlock];
   [chip8 release];

   DestroyProgram();
   DestroySound();

   if ([EAGLContext currentContext] == context) {
      [EAGLContext setCurrentContext:nil];
   }

   [context release];
   [super dealloc];

}

@end


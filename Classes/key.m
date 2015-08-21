
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "key.h"
#import "interpret.h"

/*
 * 1 2 3 C
 * 4 5 6 D
 * 7 8 9 E
 * A 0 B F
 */

static const unsigned char chip8_key_map[] = {
   1,  2,  3, 12,
   4,  5,  6, 13,
   7,  8,  9, 14,
   10, 0, 11, 15
};

static const unsigned char schip_key_map[] = {
   0,   3,  2,  1,
   7,   5,  8,  4,
   9,   6, 10, 11,
   12, 13, 14, 15
/*
   7,  8,  9, 12,
   4,  5,  6, 13,
   1,  2,  3, 14,
   0, 10, 11, 15
*/
};

#define SIZE_X       64.0
#define SIZE_Y       48.0
#define SCALE_X      (SIZE_X + 8.0)
#define SCALE_Y      (SIZE_Y + 8.0)
#define OFFSET_X     (320.0 / 2.0 - 4.0 * SCALE_X / 2.0)
#define OFFSET_Y     (480.0 / 2.0 + 480.0 / 4.0 - 4.0 * SCALE_Y / 2.0)

static void *buffer = NULL;
static size_t buffer_size = 0;
static const unsigned char *key_map = schip_key_map;

static GLuint key_textures[16] = { 0 };

static const GLfloat vertices[] = {
   0.0,     0.0,
   SIZE_X,  0.0,
   0.0,     SIZE_Y,
   SIZE_X,  SIZE_Y
};

static const GLshort texture_coordinates[] = {
   0, 0, 1, 0, 0, 1, 1, 1
};

static GLuint CreateTextTexture(int width, int height, const char *str);
static void *GetBuffer(size_t size);

void ClearKeys() {

   if(buffer) {
      free(buffer);
      buffer = NULL;
      buffer_size = 0;
   }

   int x = 0;
   for(; x < 16; x++) {
      if(key_textures[x]) {
         glDeleteTextures(1, &key_textures[x]);
      }
   }

}

void AddKey(unsigned int index, const char *str) {

   if(index > 15 || str == NULL) {
      return;
   }

   if(key_textures[index]) {
      glDeleteTextures(1, &key_textures[index]);
   }

   key_textures[index] = CreateTextTexture(64, 64, str);

}

void DrawKeys() {

   if(buffer) {
      free(buffer);
      buffer = NULL;
      buffer_size = 0;
   }

   glEnable(GL_TEXTURE_2D);
   glVertexPointer(2, GL_FLOAT, 0, vertices);
   glTexCoordPointer(2, GL_SHORT, 0, texture_coordinates);
   glEnableClientState(GL_TEXTURE_COORD_ARRAY);

   int x, y;

   for(y = 0; y < 4; y++) {
      glLoadIdentity();
      glTranslatef(OFFSET_X, y * SCALE_Y + OFFSET_Y, 0.0);
      for(x = 0; x < 4; x++) {
         const int tindex = y * 4 + x;
         if(key_textures[tindex]) {
            glBindTexture(GL_TEXTURE_2D, key_textures[tindex]);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
         }
         glTranslatef(SCALE_X, 0.0, 0.0);
      }
   }
   glDisableClientState(GL_TEXTURE_COORD_ARRAY);
   glDisable(GL_TEXTURE_2D);

}

void RegisterKeyPress(int x, int y) {

   if(x < OFFSET_X || x >= OFFSET_X + 4 * SCALE_X) {
      return;
   }
   if(y < OFFSET_Y || y >= OFFSET_Y + 4 * SCALE_Y) {
      return;
   }

   x -= OFFSET_X;
   y -= OFFSET_Y;
   x /= SCALE_X;
   y /= SCALE_Y;

   const unsigned char index = (unsigned char)(y * 4 + x);
   UpdateKey(key_map[index], 1);

}

GLuint CreateTextTexture(int width, int height, const char *str) {

   void *data;
   CGContextRef context;
   CGColorSpaceRef color_space;
   GLuint texture;
   const float font_size = 24.0;

   data = GetBuffer(width * height * 4);
   if(!data) {
      return 0;
   }

   color_space = CGColorSpaceCreateDeviceRGB();
   context = CGBitmapContextCreate(data, height, width, 8, height * 4,
                                   color_space, kCGImageAlphaPremultipliedLast);
   CGColorSpaceRelease(color_space);
   CGContextSaveGState(context);

   // Translation necessry for displaying the string in the right place.
   CGContextTranslateCTM(context, width / 2.0 - font_size / 4.0,
                         height / 2.0 - font_size / 4.0);

   // Font properties.
   CGContextSelectFont(context, "Helvetica-Bold", font_size,
                       kCGEncodingMacRoman);
   CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0); 

   // Display the string.
   CGContextShowText(context, str, strlen(str));

   CGContextRestoreGState(context);
   CGContextRelease(context);

   // Create the OpenGL texture.
   glGenTextures(1, &texture);
   glBindTexture(GL_TEXTURE_2D, texture);
   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, height, width, 0,
                GL_RGBA, GL_UNSIGNED_BYTE, data);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

   return texture;

}

void *GetBuffer(size_t size) {
   if(size > buffer_size) {
      if(buffer) {
         free(buffer);
      }
      buffer = malloc(size);
   }
   return buffer;
}


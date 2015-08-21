
#import "interpret.h"
#import "sound.h"

#import <stdlib.h>
#import <string.h>

static const unsigned char chip8_font[] = {
   0xF0, 0x90, 0x90, 0x90, 0xF0,
   0x10, 0x10, 0x10, 0x10, 0x10,
   0xF0, 0x10, 0xF0, 0x80, 0xF0,
   0xF0, 0x10, 0xF0, 0x10, 0xF0,
   0x90, 0x90, 0xF0, 0x10, 0x10,
   0xF0, 0x80, 0xF0, 0x10, 0xF0,
   0x80, 0x80, 0xF0, 0x90, 0xF0,
   0xF0, 0x10, 0x10, 0x10, 0x10,
   0xF0, 0x90, 0xF0, 0x90, 0xF0,
   0xF0, 0x90, 0xF0, 0x10, 0x10,
   0x60, 0x90, 0xF0, 0x90, 0x90,
   0xE0, 0x90, 0xE0, 0x90, 0xE0,
   0x60, 0x80, 0x80, 0x80, 0x60,
   0xE0, 0x90, 0x90, 0x90, 0xE0,
   0xF0, 0x80, 0xE0, 0x80, 0xF0,
   0xF0, 0x80, 0xE0, 0x80, 0x80
};

static const unsigned char schip_font[] = {
   0xFF, 0xFF, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xFF, 0xFF,    // 0
   0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03,    // 1
   0xFF, 0xFF, 0x03, 0x03, 0xFF, 0xFF, 0xC0, 0xC0, 0xFF, 0xFF,    // 2
   0xFF, 0xFF, 0x03, 0x03, 0xFF, 0xFF, 0x03, 0x03, 0xFF, 0xFF,    // 3
   0xC3, 0xC3, 0xC3, 0xC3, 0xFF, 0xFF, 0x03, 0x03, 0x03, 0x03,    // 4
   0xFF, 0xFF, 0xC0, 0xC0, 0xFF, 0xFF, 0x03, 0x03, 0xFF, 0xFF,    // 5
   0xC0, 0xC0, 0xC0, 0xC0, 0xFF, 0xFF, 0xC3, 0xC3, 0xFF, 0xFF,    // 6
   0xFF, 0xFF, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03,    // 7
   0xFF, 0xFF, 0xC3, 0xC3, 0xFF, 0xFF, 0xC3, 0xC3, 0xFF, 0xFF,    // 8
   0xFF, 0xFF, 0xC3, 0xC3, 0xFF, 0xFF, 0x03, 0x03, 0x03, 0x03     // 9
};

int should_exit;

static unsigned char vregs[16];
static unsigned short ireg;
static unsigned short program_counter;
static unsigned short stack_pointer;
static unsigned short instruction;
static unsigned char delay_timer;
static unsigned char sound_timer;
static unsigned int screen_width;
static unsigned int screen_height;
static unsigned char flags[16];

static unsigned char last_key;
static unsigned char *await_key;

static char screen_updated;

static unsigned char code[4096];
static unsigned char *screen;
static unsigned char keys[16];

static void ExecuteClass0();
static void ExecuteClass1();
static void ExecuteClass2();
static void ExecuteClass3();
static void ExecuteClass4();
static void ExecuteClass5();
static void ExecuteClass6();
static void ExecuteClass7();
static void ExecuteClass8();
static void ExecuteClass9();
static void ExecuteClassA();
static void ExecuteClassB();
static void ExecuteClassC();
static void ExecuteClassD();
static void ExecuteClassE();
static void ExecuteClassF();

static void ScrollDown(unsigned int count);
static void ScrollLeft();
static void ScrollRight();
static void SetScreenSize(unsigned int width, unsigned int height);

void LoadProgram(const char *data, size_t size) {

   // Clear out the program and clear the screen.
   memset(code, 0, sizeof(code));
   memset(keys, 0, sizeof(keys));

   // Start up in CHIP-8 mode by default.
   screen_width = 64;
   screen_height = 32;
   screen = malloc(screen_width * screen_height / 8);
   memset(screen, 0, screen_width * screen_height / 8);

   // Load CHIP8 fonts at 0x0000.
   memcpy(&code[0x000], chip8_font, sizeof(chip8_font));

   // Load SCHIP fonts at 0x0100.
   memcpy(&code[0x100], schip_font, sizeof(schip_font));

   // Load the program at 0x0200.
   memcpy(&code[0x200], data, size);

   // Reset.
   memset(vregs, 0, sizeof(vregs));
   ireg = 0;
   program_counter = 0x0200;
   stack_pointer = 0x0FFE;
   delay_timer = 0;
   sound_timer = 0;
   screen_updated = 1;
   last_key = 0xFF;
   await_key = NULL;
   should_exit = 0;

}

void DestroyProgram() {
   if(screen) {
      free(screen);
      screen = NULL;
   }
}

void ExecuteInstruction() {

   if(await_key) {
      if(last_key != 0xFF) {
         *await_key = last_key;
         await_key = NULL;
      }
      return;
   }

   // Load the current instruction and update the program counter.
   instruction = (code[program_counter] << 8)
               | (code[program_counter + 1]);
   program_counter += 2;

   // Switch based on the instruction type.
   switch(instruction >> 12) {
   case 0x0: ExecuteClass0(); break;
   case 0x1: ExecuteClass1(); break;
   case 0x2: ExecuteClass2(); break;
   case 0x3: ExecuteClass3(); break;
   case 0x4: ExecuteClass4(); break;
   case 0x5: ExecuteClass5(); break;
   case 0x6: ExecuteClass6(); break;
   case 0x7: ExecuteClass7(); break;
   case 0x8: ExecuteClass8(); break;
   case 0x9: ExecuteClass9(); break;
   case 0xA: ExecuteClassA(); break;
   case 0xB: ExecuteClassB(); break;
   case 0xC: ExecuteClassC(); break;
   case 0xD: ExecuteClassD(); break;
   case 0xE: ExecuteClassE(); break;
   case 0xF: ExecuteClassF(); break;
   }

}

void UpdateKey(unsigned char index, unsigned char value) {
   memset(keys, 0, sizeof(keys));
   if(value) {
      last_key = index;
   }
   keys[index] = value;
}

void ReleaseKeys() {
   memset(keys, 0, sizeof(keys));
}

int ShouldUpdateScreen() {
   const int temp = screen_updated;
   screen_updated = 0;
   return temp;
}

unsigned int GetScreenWidth() {
   return screen_width;
}

unsigned int GetScreenHeight() {
   return screen_height;
}

int GetScreenPixel(unsigned int x, unsigned int y) {

   if(x > screen_width || y > screen_height) {
      return 0;
   }

   unsigned int byte = y * (screen_width / 8) + x / 8;
   unsigned int shift = 7 - x % 8;
   return (screen[byte] >> shift) & 1;

}

int UpdateTimers() {

   const int result = sound_timer;

   if(delay_timer > 0) {
      --delay_timer;
   }
   if(sound_timer > 0) {
      if((sound_timer & 0x07) == 1) {
         PlayBeep();
      }
      --sound_timer;
   }

   return result;
}

void ExecuteClass0() {

   // Call RCA 1802 program at the specified address.
   switch(instruction) {
   case 0x00CF:   // Scroll down 15 lines.
      ScrollDown(15);
      break;
   case 0x00CE:   // Scroll down 14 lines.
      ScrollDown(14);
      break;
   case 0x00CD:   // Scroll down 13 lines.
      ScrollDown(13);
      break;
   case 0x00CC:   // Scroll down 12 lines.
      ScrollDown(12);
      break;
   case 0x00CB:   // Scroll down 11 lines.
      ScrollDown(11);
      break;
   case 0x00CA:   // Scroll down 10 lines.
      ScrollDown(10);
      break;
   case 0x00C9:   // Scroll down 9 lines.
      ScrollDown(9);
      break;
   case 0x00C8:   // Scroll down 8 lines.
      ScrollDown(8);
      break;
   case 0x00C7:   // Scroll down 7 lines.
      ScrollDown(7);
      break;
   case 0x00C6:   // Scroll down 6 lines.
      ScrollDown(6);
      break;
   case 0x00C5:   // Scroll down 5 lines.
      ScrollDown(5);
      break;
   case 0x00C4:   // Scroll down 4 lines.
      ScrollDown(4);
      break;
   case 0x00C3:   // Scroll down 3 lines.
      ScrollDown(3);
      break;
   case 0x00C2:   // Scroll down 2 lines.
      ScrollDown(2);
      break;
   case 0x00C1:   // Scroll down 1 line.
      ScrollDown(1);
   case 0x00C0:   // Scroll down 0 lines.
      // Nothing to do.
      break;
   case 0x00E0:   // Clear screen.
      memset(screen, 0, screen_width * screen_height / 8);
      screen_updated = 1;
      break;
   case 0x00EE:   // Return from subroutine.
      stack_pointer = (stack_pointer + 2) & 0x0FFF;
      program_counter = (code[stack_pointer] << 8)
                      | (code[stack_pointer + 1]);
      break;
   case 0x00FB:   // Scroll 4 pixels right.
      ScrollRight();
      break;
   case 0x00FC:   // Scroll 4 pixels left.
      ScrollLeft();
      break;
   case 0x00FD:   // Exit
      should_exit = 1;
      break;
   case 0x00FE:   // Set CHIP-8 graphics mode.
      SetScreenSize(64, 32);
      break;
   case 0x00FF:   // Set SCHIP graphics mode.
      SetScreenSize(128, 64);
      break;
   default:
      // Ignore everything else.
      break;
   }

}

void ExecuteClass1() {

   // Jump to address.
   program_counter = instruction & 0x0FFF;

}

void ExecuteClass2() {

   // Call address.
   code[stack_pointer] = program_counter >> 8;
   code[stack_pointer + 1] = program_counter & 0xFF;
   stack_pointer -= 2;
   program_counter = instruction & 0x0FFF;

}

void ExecuteClass3() {

   // Skip the next instruction if Vx = NN.
   if(vregs[(instruction >> 8) & 15] == (instruction & 0xFF)) {
      program_counter += 2;
   }

}

void ExecuteClass4() {

   // Skip the next instruction if Vx != NN.
   if(vregs[(instruction >> 8) & 15] != (instruction & 0xFF)) {
      program_counter += 2;
   }

}

void ExecuteClass5() {

   // Skip the next instruction if Vx = Vy.
   if(vregs[(instruction >> 8) & 15] == vregs[(instruction >> 4) & 15]) {
      program_counter += 2;
   }

}

void ExecuteClass6() {

   // Set Vx to NN.
   vregs[(instruction >> 8) & 15] = instruction & 0xFF;

}

void ExecuteClass7() {

   // Set Vx = Vx + NN.
   vregs[(instruction >> 8) & 15] += instruction & 0xFF;

}

void ExecuteClass8() {

   unsigned char *vx = &vregs[(instruction >> 8) & 15];
   unsigned char *vy = &vregs[(instruction >> 4) & 15];

   switch(instruction & 15) {
   case 0x0:   // Vx = Vy
      *vx = *vy;
      break;
   case 0x1:   // Vx = Vx | Vy
      *vx |= *vy;
      break;
   case 0x2:   // Vx = Vx & Vy
      *vx &= *vy;
      break;
   case 0x3:   // Vx = Vx ^ Vy
      *vx ^= *vy;
      break;
   case 0x4:   // Vx = Vx + Vy (VF set to 1 on carry, 0 otherwise).
      vregs[0xF] = *vx + *vy > 255 ? 1 : 0;
      *vx += *vy;
      break;
   case 0x5:   // Vx = Vx - Vy (VF set to 0 on borrow, 1 otherwise).
      vregs[0xF] = *vx >= *vy ? 1 : 0;
      *vx = *vx - *vy;
      break;
   case 0x6:   // Vx = Vx >> 1 (VF set to LSb before shift).
      vregs[0xF] = *vx & 1;
      *vx >>= 1;
      break;
   case 0x7:   // Vx = Vy - Vx (VF set to 0 on borrow, 1 otherwise).
      vregs[0xF] = *vy >= *vx ? 1 : 0;
      *vx = *vy - *vx;
      break;
   case 0xE:   // Vx = Vx << 1 (VF set to the MSb before shift).
      vregs[0xF] = *vx >> 7;
      *vx <<= 1;
      break;
   default:
      // Ignore anything else.
      break;
   }

}

void ExecuteClass9() {

   // Skip the next instruction if Vx != Vy.
   if(vregs[(instruction >> 8) & 15] != vregs[(instruction >> 4) & 15]) {
      program_counter += 2;
   }

}

void ExecuteClassA() {

   // Set I to NNN.
   ireg = instruction & 0x0FFF;

}

void ExecuteClassB() {

   // Jump to NNN + V0.
   program_counter = (instruction & 0x0FFF) + vregs[0];

}

void ExecuteClassC() {

   // Set VX to rand & NN.
   vregs[(instruction >> 8) & 15] = rand() & (instruction & 0xFF);

}

void ExecuteClassD() {

   // Draw (XOR) sprite at (Vx, Vy).
   // Width is 8 pixels and height is N pixels.
   // VF set to 1 if a pixel is flipped from set to unset, 0 otherwise.
   // Address in I.
   // If N=0, draw a 16x16 sprite.

   unsigned char xc = vregs[(instruction >> 8) & 15];
   unsigned char yc = vregs[(instruction >> 4) & 15];

   unsigned char height = instruction & 15;
   unsigned char width = 8;
   if(height == 0) {
      if(screen_width == 128) {
         width = 16;
      }
      height = 16;
   }

   vregs[0xF] = 0;

   unsigned char x, y;
   unsigned short addr = ireg;
   unsigned short src_byte, src_shift, src_bit;
   unsigned short dest_byte, dest_shift, dest_bit;
   unsigned char destx, desty;
   for (y = 0; y < height; y++) {
      desty = (y + yc) % screen_height;
      for(x = 0; x < width; x++) {
         destx = (x + xc) % screen_width;
         src_byte = x / 8;
         src_shift = 7 - x % 8;
         src_bit = (code[(addr + src_byte) & 0x0FFF] >> src_shift) & 1;
         dest_byte = desty * (screen_width / 8) + destx / 8;
         dest_shift = 7 - destx % 8;
         dest_bit = (screen[dest_byte] >> dest_shift) & 1;
         if(src_bit & dest_bit) {
            vregs[0xF] = 1;
         }
         screen[dest_byte] ^= src_bit << dest_shift;
      }
      addr += width / 8;
   }

   screen_updated = 1;

}

void ExecuteClassE() {

   const unsigned char vx = vregs[(instruction >> 8) & 15];

   switch(instruction & 0xFF) {
   case 0x9E:  // Skip the next instruction if key Vx is pressed.
      if(keys[vx & 15]) {
         program_counter += 2;
      }
      break;
   case 0xA1:  // Skip the next instruction if the key Vx is not pressed.
      if(!keys[vx & 15]) {
         program_counter += 2;
      }
      break;
   default:
      // Ignore everything else.
      break;
   }

}

void ExecuteClassF() {

   unsigned short x;
   unsigned short index = (instruction >> 8) & 15;
   unsigned char *vx = &vregs[index];

   switch(instruction & 0xFF) {
   case 0x07:  // Vx = delay timer.
      *vx = delay_timer;
      break;
   case 0x0A:  // Wait for a key and store it in Vx.
      await_key = vx;
      last_key = 0xFF;
      break;
   case 0x15:  // Set the delay timer to Vx.
      delay_timer = *vx;
      break;
   case 0x18:  // Set the sound timer to Vx.
      sound_timer = *vx;
      break;
   case 0x1E:  // Add Vx to I.
      ireg = (*vx + ireg) & 0x0FFF;
      break;
   case 0x29:  // Set I to the location of the sprite in Vx.
      if(screen_width == 64) {
         ireg = 0x000 + *vx * 5;   // CHIP-8, 5 bytes per character at 0x000.
      } else {
         ireg = 0x100 + *vx * 10; // SCHIP, 10 bytes per character at 0x100.
      }
      break;
   case 0x33:  // Store the BCD representation of Vx at I,I+1,I+2
      code[ireg] = *vx / 100;
      code[(ireg + 1) & 0x0FFF] = (*vx / 10) % 10;
      code[(ireg + 2) & 0x0FFF] = *vx % 10;
      break;
   case 0x55:  // Store V0...Vx to memory at I.
      for(x = 0; x <= index; x++) {
         code[(ireg + x) & 0x0FFF] = vregs[x];
      }
      break;
   case 0x65:  // Load V0...Vx from memory at I.
      for(x = 0; x <= index; x++) {
         vregs[x] = code[(ireg + x) & 0x0FFF];
      }
      break;
   case 0x75:  // Save V0...Vx to flags.
      for(x = 0; x <= index; x++) {
         code[(ireg + x) & 0x0FFF] = vregs[x];
      }
      break;
   case 0x85:  // Load V0...Vx from flags.
      for(x = 0; x <= index; x++) {
         flags[x] = code[(ireg + x) & 0x0FFF];
      }
      break;
   default:
      // Ignore everything else.
      break;
   }

}

void ScrollDown(unsigned int count) {

   // Number of bytes per line.
   const size_t line_bytes = screen_width / 8;

   // Compute the number of bytes to scroll.
   const size_t move_bytes = count * line_bytes;

   const size_t last_line = line_bytes * screen_height - line_bytes;

   size_t x;
   for(x = last_line; x > move_bytes; x -= line_bytes) {
      memcpy(&screen[x], &screen[x - move_bytes], line_bytes);
   }

}

void ScrollLeft() {

   int x, y;
   unsigned char temp;
   unsigned char last;

   unsigned int scroll_amount = 4;
   if(screen_width == 64) {
      scroll_amount = 2;
   }

   for(y = 0; y < screen_height; y++) {
      last = 0;
      for(x = screen_width / 8 - 1; x >= 0; x--) {
         temp = screen[y * screen_width / 8 + x];
         screen[y * screen_width / 8 + x] = (temp << scroll_amount) | last;
         last = temp >> (8 - scroll_amount);
      }
   }

}

void ScrollRight() {

   int x, y;
   unsigned char temp;
   unsigned char last;

   unsigned int scroll_amount = 4;
   if(screen_width == 64) {
      scroll_amount = 2;
   }

   for(y = 0; y < screen_height; y++) {
      last = 0;
      for(x = 0; x < screen_width / 8; x++) {
         temp = screen[y * screen_width / 8 + x];
         screen[y * screen_width / 8 + x] = last | (temp >> scroll_amount);
         last = temp << (8 - scroll_amount);
      }
   }

}

void SetScreenSize(unsigned int width, unsigned int height) {

   if(screen_width != width || screen_height != height) {
      if(screen) {
         free(screen);
      }
      screen_width = width;
      screen_height = height;
      screen = malloc(width * height / 8);
      memset(screen, 0, width * height / 8);
   }

}


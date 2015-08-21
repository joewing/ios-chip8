
#import "MenuView.h"
#import "Chip8AppDelegate.h"

@implementation MenuView

- (id)initWithFrame:(CGRect)rect {

   self = [super initWithFrame:rect];
   if(self) {

/*
      Chip8AppDelegate *d = [UIApplication sharedApplication].delegate;

      start_button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
      start_button.frame = CGRectMake(10, 10, 128, 32);
      [start_button setTitle:@"Start" forState:0];
      [start_button addTarget:d action:@selector(start)
                    forControlEvents:UIControlEventTouchUpInside];
      [self addSubview:start_button];
*/

      CGRect rect = CGRectMake(0, 64, 320, 480 - 64);
      program_picker = [[ItemPicker alloc] initWithFrame:rect];
      [program_picker setSelectionDelegate:self];
      [self addSubview:program_picker];

// TODO
      [program_picker insert:@"INVADERS"];
      [program_picker insert:@"BRIX"];
      [program_picker insert:@"BLINKY"];
      [program_picker insert:@"MAZE"];
      [program_picker insert:@"ANT"];
      [program_picker insert:@"RACE"];
      [program_picker reload];

      self.opaque = YES;
      self.backgroundColor = [UIColor darkGrayColor];

   }
   return self;

}

- (void)drawRect:(CGRect)rect {

   [super drawRect:rect];

}

- (void)transitionComplete {
}

- (void)selected:(NSString*)item {
   Chip8AppDelegate *d = [UIApplication sharedApplication].delegate;
   [program_picker resetSelection];
   [d start:item];
}

- (void)dealloc {
//   [start_button release];
   [program_picker release];
   [super dealloc];
}

@end



#import "ChipThread.h"
#import "interpret.h"

@implementation ChipThread

- (id)init {
   self = [super init];
   if(self) {
      lock = [[NSLock alloc] init];
   }
   return self;
}

- (void)lock {
   [lock lock];
}

- (void)unlock {
   [lock unlock];
}

- (void)stop {
   should_exit = 1;
}

- (void)main {

   while(!should_exit) {

      [lock lock];
      int x;
      for(x = 0; x < 20; x++) {
         ExecuteInstruction();
      }
      [lock unlock];

      usleep(10000);

   }

}

- (void)dealloc {
   [lock release];
   [super dealloc];
}

@end



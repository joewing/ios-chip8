
#import <UIKit/UIKit.h>

@interface ChipThread : NSThread {

@private

   NSLock *lock;

}

- (void)lock;
- (void)unlock;
- (void)stop;

@end


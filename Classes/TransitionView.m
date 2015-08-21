
#import <QuartzCore/QuartzCore.h>
#import "TransitionView.h"

#define kAnimationKey @"transitionView"

@implementation TransitionView

- (id)initWithFrame:(CGRect)rect {
   self = [super initWithFrame:rect];
   if(self) {
      self.backgroundColor = [UIColor blackColor];
      delegate = nil;
   }
   return self;
}

- (void)setDelegate:(id <TransitionViewDelegate>)d {
   delegate = d;
}

- (void)replace:(UIView*)old with:(UIView*)new {

   NSArray *subviews = [self subviews];
   NSUInteger index = 0;

   // Remove the old.
   if([old superview] == self) {
      for(index = 0; [subviews objectAtIndex:index] != old; ++index);
      [old removeFromSuperview];
   }

   // Insert the new.
   if([new superview] == nil) {
      [self insertSubview:new atIndex:index];
   }

   CATransition *animation = [CATransition animation];
   [animation setDelegate:self];
   [animation setType:kCATransitionPush];
   [animation setSubtype:kCATransitionFromLeft];
   [animation setDuration:0.75];
   [animation setTimingFunction:[CAMediaTimingFunction
         functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
   [[self layer] addAnimation:animation forKey:kAnimationKey];

}

- (void)cancelTransition {
   [[self layer] removeAnimationForKey:kAnimationKey];
}

- (void)animationDidStart:(CAAnimation*)animation {
   self.userInteractionEnabled = NO;
}

- (void)animationDidStop:(CAAnimation*)animation finished:(BOOL)finished {
   self.userInteractionEnabled = YES;
   [delegate transitionComplete];
}

@end


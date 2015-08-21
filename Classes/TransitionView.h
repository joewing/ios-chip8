
#import <UIKit/UIKit.h>

@protocol TransitionViewDelegate

- (void)transitionComplete;

@end

@interface TransitionView : UIView {

@private

   id <TransitionViewDelegate> delegate;

}

- (void)setDelegate:(id <TransitionViewDelegate>)d;

- (void)replace:(UIView*)old with:(UIView*)new;

@end


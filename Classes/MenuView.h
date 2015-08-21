
#import <UIKit/UIKit.h>
#import "TransitionView.h"
#import "ItemPicker.h"

@interface MenuView : UIView <TransitionViewDelegate, ItemPickerDelegate> {
   UIButton *start_button;
   ItemPicker *program_picker;
}

@end


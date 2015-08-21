
#import <UIKit/UIKit.h>

@protocol ItemPickerDelegate

- (void)selected:(NSString*)item;

@end

@interface ItemPicker : UITableView
                        <UITableViewDataSource, UITableViewDelegate> {

@private

   NSMutableArray *table_cells;
   id<ItemPickerDelegate> item_delegate;

}

- (void)setSelectionDelegate:(id<ItemPickerDelegate>)d;

- (id)initWithFrame:(CGRect)rect;

- (void)insert:(NSString*)name;

- (void)reload;

- (void)resetSelection;

@end


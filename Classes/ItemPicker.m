
#import "ItemPicker.h"

static int SortFunc(id a, id b, void *context) {

   UITableViewCell *cella = (UITableViewCell*)a;
   NSString *sa = cella.text;
   UITableViewCell *cellb = (UITableViewCell*)b;
   NSString *sb = cellb.text;

   NSComparisonResult cr = [sa caseInsensitiveCompare:sb];
   switch(cr) {
   case NSOrderedAscending:
      return -1;
   case NSOrderedDescending:
      return 1;
   default:
      return 0;
   }

}

@implementation ItemPicker

- (id)initWithFrame:(CGRect)rect {

   self = [super initWithFrame:rect style:UITableViewStylePlain];
   if(self) {

      super.delegate = self;
      super.dataSource = self;
      item_delegate = nil;

      table_cells = [[NSMutableArray alloc] initWithCapacity:16];

   }
   return self;

}

- (UITableViewCell*)tableView:(UITableView*)tableView
                    cellForRowAtIndexPath:(NSIndexPath*)indexPath {

   NSUInteger index = [indexPath indexAtPosition:1];
   UITableViewCell *cell = (UITableViewCell*)[table_cells objectAtIndex:index];
   return cell;

}

- (NSInteger)tableView:(UITableView*)tableView
             numberOfRowsInSection:(NSInteger)section {

   NSInteger count = (NSInteger)[table_cells count];
   return count;

}

- (void)tableView:(UITableView*)tableView
        didSelectRowAtIndexPath:(NSIndexPath*)indexPath {

   NSUInteger index = [indexPath indexAtPosition:1];
   UITableViewCell *cell = (UITableViewCell*)[table_cells objectAtIndex:index];
   NSString *item = cell.text;
   [item_delegate selected:item];

}

- (void)setSelectionDelegate:(id<ItemPickerDelegate>)d {
   item_delegate = d;
}

- (void)insert:(NSString*)name {
   UITableViewCell *cell = [UITableViewCell alloc];
   [cell initWithFrame:CGRectZero reuseIdentifier:nil];
   cell.text = name;
   [table_cells addObject:cell];
}

- (void)reload {
   [table_cells sortUsingFunction:SortFunc context:NULL];
   [super reloadData];
}

- (void)resetSelection {

   NSIndexPath *path = [super indexPathForSelectedRow];
   if(path) {
      [super deselectRowAtIndexPath:path animated:NO];
   }

}

@end


/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller that presents the SSM selection interface.
*/

@import UIKit;

@protocol ItemSelectionViewControllerDelegate;

@interface ItemSelectionViewController<Item>: UITableViewController

- (id)initWithDelegate:(id<ItemSelectionViewControllerDelegate>)delegate identifier:(NSString *)identifier allItems:(NSArray*)allitems selectedItems:(NSArray*)selectedItems allowMultipleSelection:(BOOL)allowMultipleSelection;
- (IBAction) done:(id)sender;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@protocol ItemSelectionViewControllerDelegate <NSObject>

@required
- (void)itemSelectionViewController:(ItemSelectionViewController*)it didFinishSelectingItems:(NSArray *)selectedItems;

@end

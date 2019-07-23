/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller that presents the SSM selection interface.
*/

#include "ItemSelectionViewController.h"


@implementation ItemSelectionViewController
{
	id<ItemSelectionViewControllerDelegate> _delegate;

	NSString *_identifier;
	NSArray<id> *_allItems;
	NSMutableArray<id> *_selectedItems;
	BOOL _allowMultipleSelection;
	NSString *itemCellIdentifier;
}


- (id)initWithDelegate:(id<ItemSelectionViewControllerDelegate>)delegate identifier:(NSString *)identifier allItems:(NSArray*)allitems selectedItems:(NSArray*)selectedItems allowMultipleSelection:(BOOL)allowMultipleSelection
{
	self = [super initWithStyle:UITableViewStyleGrouped];
	_delegate = delegate;
	_identifier = identifier;
	_allItems = allitems;
	_selectedItems = [NSMutableArray arrayWithArray:selectedItems];
	_allowMultipleSelection = allowMultipleSelection;
	itemCellIdentifier = @"item";
	self.tableView.allowsMultipleSelection = allowMultipleSelection;
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
	
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:itemCellIdentifier];
	
	return self;
}

- (IBAction) done:(id)sender
{
	[_delegate itemSelectionViewController:self didFinishSelectingItems:_selectedItems];
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	id item = _allItems[indexPath.row];
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:itemCellIdentifier forIndexPath:indexPath];
	cell.tintColor = UIColor.blackColor;
	
	NSString *textLabel = (NSString *)item;
	if ( [textLabel containsString:@"Skin"] != 0) {
		cell.textLabel.text = @"Skin";
	}
	else if ( [textLabel containsString:@"Teeth"] != 0) {
		cell.textLabel.text = @"Teeth";
	}
	else if ( [textLabel containsString:@"Hair"] != 0) {
		cell.textLabel.text = @"Hair";
	}
	else {
		cell.textLabel.text = @"Not supported";
	}
	
	
	if ( [_selectedItems containsObject: item] ) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _allItems.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ( _allowMultipleSelection ) {
		id item = _allItems[indexPath.row];
		
		if ( [_selectedItems containsObject:item] ) {
			[_selectedItems removeObject:item];
		}
		else {
			[_selectedItems addObject:item];
		}
		
		[self.tableView deselectRowAtIndexPath:indexPath animated:true];
		[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	}
}

@end

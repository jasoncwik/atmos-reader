

#import "RootViewController.h"


@implementation RootViewController

@synthesize popoverController, splitViewController, rootPopoverButtonItem, collContentsViewCtrl;


#pragma mark -
#pragma mark Initial configuration

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Set the content size for the popover: there are just two rows in the table view, so set to rowHeight*2.
    self.contentSizeForViewInPopover = CGSizeMake(310.0, 480.0);
	
	//UIImage *bgImg = [UIImage imageNamed:@"bg_img.png"];
	//UIColor *bgColor = [UIColor	colorWithPatternImage:bgImg];
	//self.tableView.backgroundColor = bgColor;
}


#pragma mark -
#pragma mark Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


- (void)splitViewController:(UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController:(UIPopoverController*)pc {
    
    // Keep references to the popover controller and the popover button, and tell the detail view controller to show the button.
    barButtonItem.title = @"Collections";
    self.popoverController = pc;
    self.rootPopoverButtonItem = barButtonItem;
	UINavigationController *navCtrl = [splitViewController.viewControllers objectAtIndex:1];
	NSLog(@"%@",[navCtrl.viewControllers objectAtIndex:0]);
    UIViewController <SubstitutableDetailViewController> *detailViewController = [navCtrl.viewControllers objectAtIndex:0];
    [detailViewController showRootPopoverButtonItem:rootPopoverButtonItem];
}


- (void)splitViewController:(UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
 
    // Nil out references to the popover controller and the popover button, and tell the detail view controller to hide the button.
	UINavigationController *navCtrl = [splitViewController.viewControllers objectAtIndex:1];
	NSLog(@"%@",[navCtrl.viewControllers objectAtIndex:0]);
    UIViewController <SubstitutableDetailViewController> *detailViewController = [navCtrl.viewControllers objectAtIndex:0];
    [detailViewController invalidateRootPopoverButtonItem:rootPopoverButtonItem];
    self.popoverController = nil;
    self.rootPopoverButtonItem = nil;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    
	if(section == 0) {
		return 2;
	} else {
		AtmosLocalStore *store = [AtmosLocalStore getSharedInstance];
		[store loadCategoryStubs];
		return store.categoryStubs.count;
	}
	
}


- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"RootViewControllerCellIdentifier";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	if(indexPath.section == 0) {
		if(indexPath.row == 0) {
			cell.textLabel.text = @"Recents";
			cell.imageView.image = [UIImage imageNamed:@"recents_icon.png"];
		} else if(indexPath.row == 1) {
			cell.textLabel.text = @"Favorites";
			cell.imageView.image = [UIImage imageNamed:@"favorites_icon_32x32.png"];
		}
	} else {
		AtmosLocalStore *store = [AtmosLocalStore getSharedInstance];
		AtmosObject *obj = [[store.categoryStubs allValues] objectAtIndex:indexPath.row];
		cell.textLabel.text = obj.objectName;
		cell.imageView.image = [UIImage imageNamed:@"collection_icon_32x32.png"];
	}
    return cell;
}


#pragma mark -
#pragma mark Table view selection

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    UIViewController <SubstitutableDetailViewController> *detailViewController = nil;
	AtmosLocalStore *store = [AtmosLocalStore getSharedInstance];
	
	if(indexPath.section == 0) {
		if(indexPath.row == 0) {
			//recents
			self.collContentsViewCtrl.collContents = [store getRecentItems:30];
		} else if (indexPath.row == 1) {
			self.collContentsViewCtrl.collContents = [store getAllFavorites];
		}
	} else if(indexPath.section == 1) {
		AtmosObject *aobj = [[store.categoryStubs allValues] objectAtIndex:indexPath.row];
		NSLog(@"selected atmos id %@",aobj.atmosId);
		self.collContentsViewCtrl.collContents = [store getAllCollectionItems:aobj.atmosId];
	}
	
	[self.collContentsViewCtrl.tableView reloadData];
	
    // Dismiss the popover if it's present.
    if (popoverController != nil) {
        [popoverController dismissPopoverAnimated:YES];
    }

    // Configure the new view controller's popover button (after the view has been displayed and its toolbar/navigation bar has been created).
    if (rootPopoverButtonItem != nil) {
        [detailViewController showRootPopoverButtonItem:self.rootPopoverButtonItem];
    }

    [detailViewController release];
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [popoverController release];
    [rootPopoverButtonItem release];
    [super dealloc];
}

@end

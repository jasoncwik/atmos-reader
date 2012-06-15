

#import <UIKit/UIKit.h>
#import "AtmosLocalStore.h"
#import "CollectionContentsViewController.h"

/*
 SubstitutableDetailViewController defines the protocol that detail view controllers must adopt. The protocol specifies methods to hide and show the bar button item controlling the popover.

 */
@protocol SubstitutableDetailViewController
- (void)showRootPopoverButtonItem:(UIBarButtonItem *)barButtonItem;
- (void)invalidateRootPopoverButtonItem:(UIBarButtonItem *)barButtonItem;
@end


@interface RootViewController : UITableViewController <UISplitViewControllerDelegate> {
	
	UISplitViewController *splitViewController;
	
	CollectionContentsViewController *collContentsViewCtrl;
    
    UIPopoverController *popoverController;    
    UIBarButtonItem *rootPopoverButtonItem;
	
}

@property (nonatomic, assign) IBOutlet UISplitViewController *splitViewController;
@property (nonatomic, retain) IBOutlet CollectionContentsViewController *collContentsViewCtrl;
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) UIBarButtonItem *rootPopoverButtonItem;

@end

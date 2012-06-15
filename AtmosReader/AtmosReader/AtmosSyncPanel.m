    //
//  AtmosSyncPanel.m
//  AtmosReader
//
//  Created by Aashish Patil on 4/16/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "AtmosSyncPanel.h"


@implementation AtmosSyncPanel

@synthesize activityIndicator;
@synthesize statusLabel;
@synthesize doneButton;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

- (void)viewWillAppear:(BOOL)animated {
	AtmosLocalStore *store = [AtmosLocalStore getSharedInstance];
	if([store isReachable]) {
		//One could get quite creative with the network status if required. Keeping it simple here
		store.syncCompleteListener = self;
		[store performSync];
		[self.activityIndicator startAnimating];
		self.statusLabel.text = @"Performing Sync";
		self.doneButton.enabled = NO;
	} else {
		self.statusLabel.text = @"Sorry, no network connection detected";
	}
}


- (IBAction) cancelSync:(id) sender {
	[[AtmosLocalStore getSharedInstance] cancelSync];
	[self.presentingViewController dismissModalViewControllerAnimated:YES];
}

- (IBAction) doneWithSync:(id) sender {
	//refresh data
	
	[self.presentingViewController dismissModalViewControllerAnimated:YES];
}

- (void) finishedSync {
	[self.activityIndicator stopAnimating];
	self.statusLabel.text = @"Finished Sync";
	self.doneButton.enabled = YES;
	AppDelegate_Pad	*appDel = (AppDelegate_Pad *) [[UIApplication sharedApplication] delegate];
	[appDel reloadDataInViews];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

    //
//  AtmosSettingsPanel.m
//  AtmosReader
//
//  Created by Aashish Patil on 4/16/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "AtmosSettingsPanel.h"

@interface AtmosSettingsPanel (Private) 

- (void) saveSettings;
- (void) loadSettings;


@end


@implementation AtmosSettingsPanel

@synthesize accessPoint,tokenID,sharedSecret;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
	UIBarButtonItem *doneBut = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleDone target:self action:@selector(doneWithSettings)];
	self.navigationItem.rightBarButtonItem = doneBut;
	
	[super viewDidLoad];
	
}



- (void)viewWillAppear:(BOOL)animated {
	
	[self loadSettings];
	
}

- (void)viewWillDisappear:(BOOL)animated {
	[self saveSettings];
	AppDelegate_Pad *appDel = (AppDelegate_Pad *) [[UIApplication sharedApplication] delegate];
	[appDel saveAtmosSettings];
}


- (void) saveSettings {
	AtmosCredentials *creds = [AtmosLocalStore getSharedInstance].atmosCredentials;
	creds.accessPoint = (self.accessPoint.text) ? (self.accessPoint.text) : @"";
	creds.tokenId = (self.tokenID.text) ? (self.tokenID.text) : @"";
	creds.sharedSecret =(self.sharedSecret.text) ? (self.sharedSecret.text) : @"";
}

- (void) loadSettings {
	AtmosCredentials *creds = [AtmosLocalStore getSharedInstance].atmosCredentials;
	self.accessPoint.text = (creds.accessPoint) ? (creds.accessPoint) : @"";
	self.tokenID.text = (creds.tokenId) ? (creds.tokenId) : @"";
	self.sharedSecret.text = (creds.sharedSecret) ? (creds.sharedSecret) :  @"";
	
}

- (IBAction) doneWithSettings {
	//NSLog(@"doneWithSetings called %@",self.navigationController);
    NSLog(@"parentViewcontroller %@",self.parentViewController);
	[self.presentingViewController dismissViewControllerAnimated:YES
                                                  completion:^{
                                                      //noop
                                                  }];
	
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

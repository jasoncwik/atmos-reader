    //
//  ProgressViewController.m
//  AtmosReader
//
//  Created by Aashish Patil on 6/4/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "ProgressViewController.h"


@implementation ProgressViewController

@synthesize progressView,activityIndicatorView,statusLabel,atmosObj;

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
    [super viewDidLoad];
	
}


- (void)viewWillAppear:(BOOL)animated {
	[self startDownload:nil];
	
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


#pragma mark AtmosProgressListenerDelegate

- (void) operationProgress:(AtmosProgressEvent *) event {
	if(event.complete == YES) {
		self.progressView.progress = 1.0;
		[self downloadComplete];
	} else if(event.failed == YES) {
		self.progressView.progress = 1.0;
		self.statusLabel.text = [NSString stringWithFormat:@"Download failed: %@",event.errorMsg];
		[self.activityIndicatorView stopAnimating];
	} else {
		self.progressView.progress = ((float)event.completedBytes / (float)event.totalBytes);
	}
}

#pragma mark Download

- (IBAction) startDownload:(id) sender {
	if(self.atmosObj != nil) {
		[[AtmosLocalStore getSharedInstance] downloadObject:atmosObj downloadListener:self];
		self.statusLabel.text = [NSString stringWithFormat:@"Downloading %@",self.atmosObj.objectName];
		[self.activityIndicatorView startAnimating];
		self.progressView.progress = 0.0;
	}
}

- (IBAction) done:(id)sender {
	[self.presentingViewController dismissModalViewControllerAnimated:YES];
	
}

- (void) downloadComplete {
	[self.activityIndicatorView stopAnimating];
	self.statusLabel.text = [NSString stringWithFormat:@"Download complete"];
	[self done:nil];
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

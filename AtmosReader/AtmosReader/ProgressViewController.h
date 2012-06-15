//
//  ProgressViewController.h
//  AtmosReader
//
//  Created by Aashish Patil on 6/4/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AtmosObject.h"
#import "AtmosLocalStore.h"
#import "AtmosProgressListenerDelegate.h"

@interface ProgressViewController : UIViewController <AtmosProgressListenerDelegate> {
	IBOutlet UIProgressView *progressView;
	IBOutlet UIActivityIndicatorView *activityIndicatorView;
	IBOutlet UILabel *statusLabel;
	
	AtmosObject *atmosObj;
	
}	

- (IBAction) done:(id) sender;
- (IBAction) startDownload:(id) sender;

@property (nonatomic,retain) UIProgressView *progressView;
@property (nonatomic,retain) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic,retain) UILabel *statusLabel;
@property (nonatomic,retain) AtmosObject *atmosObj;

@end

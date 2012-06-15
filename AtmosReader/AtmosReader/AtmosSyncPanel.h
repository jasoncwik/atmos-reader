//
//  AtmosSyncPanel.h
//  AtmosReader
//
//  Created by Aashish Patil on 4/16/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AtmosLocalStore.h"
#import "AppDelegate_Pad.h"

@interface AtmosSyncPanel : UIViewController {

	UIActivityIndicatorView *activityIndicator;
	UILabel *statusLabel;
	UIButton *doneButton;
}

- (IBAction) cancelSync:(id) sender;
- (IBAction) doneWithSync:(id) sender;
- (void) finishedSync;

@property (nonatomic,retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic,retain) IBOutlet UILabel *statusLabel;
@property (nonatomic,retain) IBOutlet UIButton *doneButton;
@end

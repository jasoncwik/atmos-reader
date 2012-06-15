//
//  AtmosSettingsPanel.h
//  AtmosReader
//
//  Created by Aashish Patil on 4/16/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AtmosLocalStore.h"
#import "AppDelegate_Pad.h"

@interface AtmosSettingsPanel : UIViewController {
	
	UITextField *accessPoint;
	UITextField *tokenID;
	UITextField *sharedSecret;

}

- (IBAction) doneWithSettings;

@property (nonatomic,retain) IBOutlet UITextField *accessPoint;
@property (nonatomic,retain) IBOutlet UITextField *tokenID;
@property (nonatomic,retain) IBOutlet UITextField *sharedSecret;

@end

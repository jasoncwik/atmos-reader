//
//  AppDelegate_Pad.h
//  AtmosReader
//
//  Created by Aashish Patil on 4/9/10.
//  Copyright EMC 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EsuGetObjectsOperation.h"
#import "AtmosCredentials.h"
#import "AtmosLocalStore.h"

//#define TOKEN_ID
//#define SHARED_SECRET

@interface AppDelegate_Pad : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	UISplitViewController *splitViewCtrl;
	NSOperationQueue *operQ;
}

- (void) reloadDataInViews;

- (void) loadAtmosSettings;

- (void) saveAtmosSettings;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewCtrl;
@property (nonatomic, retain) NSOperationQueue *operQ;


@end


//
//  AppDelegate_Pad.m
//  AtmosReader
//
//  Created by Aashish Patil on 4/9/10.
//  Copyright EMC 2010. All rights reserved.
//

#import "AppDelegate_Pad.h"

@interface AppDelegate_Pad(Private) 

- (void) saveAtmosSettings;
- (void) loadAtmosSettings;

@end


@implementation AppDelegate_Pad

@synthesize window,operQ,splitViewCtrl;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	
    // Override point for customization after application launch
	[self loadAtmosSettings];
	
	[window addSubview:[splitViewCtrl view]];
    [window makeKeyAndVisible];
	
	return YES;
}

- (IBAction) getCategories:(id) sender {
	NSLog(@"getCategories called");
	
	AtmosCredentials *creds = [[AtmosCredentials alloc] init];
	creds.tokenId = @"c54faa5e354541579f59083a5b0952be/EMC00E2A4A6106011C67";
	creds.sharedSecret = @"mqFx1GKzBlK5yqBWDbDqp5mEYKc=";
	
	AtmosLocalStore *store = [AtmosLocalStore getSharedInstance];
	store.atmosCredentials = creds;
	store.syncCompleteListener = self;
	[store performSync];
	
	
}

- (void) loadAtmosSettings {
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	
	NSString *ap = [defs objectForKey:@"accessPoint"];
	NSString *tid = [defs objectForKey:@"tokenID"];
	NSString *ss = [defs objectForKey:@"sharedSecret"];
	NSLog(@"Just loaded atmos creds from defs %@ %@ %@",ap,tid,ss);
	
	AtmosCredentials *creds = [[AtmosCredentials alloc] init];
	creds.accessPoint = (ap) ? (ap) : @"";
	creds.tokenId = (tid) ? tid : @"";
	creds.sharedSecret = (ss) ? ss : @"";
	[AtmosLocalStore getSharedInstance].atmosCredentials = creds;
	[creds release];
	
}

- (void) saveAtmosSettings {
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	
	AtmosLocalStore *store = [AtmosLocalStore getSharedInstance];
	AtmosCredentials *creds = store.atmosCredentials;
	
	NSString *ap = (creds.accessPoint) ? creds.accessPoint : @"";
	[defs setObject:ap forKey:@"accessPoint"];
	NSLog(@"Just saved access point %@",ap);
	
	NSString *tid = (creds.tokenId) ? creds.tokenId : @"";
	[defs setObject:tid forKey:@"tokenID"];
	NSLog(@"Just saved tokenID %@",tid);
	
	NSString *ss = (creds.sharedSecret) ? creds.sharedSecret : @"";
	[defs setObject:ss forKey:@"sharedSecret"];	
	NSLog(@"Just saved shared secret %@",ss);
	
}


- (IBAction) getObjects: (id) sender {
	NSLog(@"getObjects called");
}

- (void) finishedLoadingMetadata:(id) sender {
	
	
}

- (void) reloadDataInViews {
	NSArray *viewCtrls = self.splitViewCtrl.viewControllers;
	for(int i=0;i<viewCtrls.count;i++) {
		UINavigationController *navCtrl = (UINavigationController *) [viewCtrls objectAtIndex:i];
		UITableViewController *tableCtrl = (UITableViewController *) [navCtrl.viewControllers objectAtIndex:0];
		[tableCtrl.tableView reloadData];
	}
	
}

- (void) finishedSync {
	NSLog(@"sync complete");
	NSLog(@"iterating categories");
	AtmosLocalStore *store = [AtmosLocalStore getSharedInstance];
	NSArray *catKeys = [store.categoryStubs allKeys];
	for(int i=0;i<catKeys.count;i++) {
		NSString *key = [catKeys objectAtIndex:i];
		AtmosObject *obj = [store.categoryStubs objectForKey:key];
		NSLog(@"%@ %@ %@",key,obj.objectName,obj.categoryId);
	}
	
	NSLog(@"now iterating objects");
	NSArray *objKeys = [store.objectStubs allKeys];
	for(int i=0;i<objKeys.count;i++) {
		NSString *key = [objKeys objectAtIndex:i];
		AtmosObject *obj = [store.objectStubs objectForKey:key];
		NSLog(@"%@ %@ %@",key,obj.objectName,obj.categoryId);
	}
	
	
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[self saveAtmosSettings];
	[[AtmosLocalStore getSharedInstance] closeStore];
}


- (void)dealloc {
    [window release];
    [super dealloc];
}


@end

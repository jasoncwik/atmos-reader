//
//  AppDelegate_Phone.m
//  AtmosReader
//
//  Created by Aashish Patil on 4/9/10.
//  Copyright EMC 2010. All rights reserved.
//

#import "AppDelegate_Phone.h"

@implementation AppDelegate_Phone

@synthesize window;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	
    // Override point for customization after application launch
	
    [window makeKeyAndVisible];
	
	return YES;
}


- (void)dealloc {
    [window release];
    [super dealloc];
}


@end

//
//  AtmosSyncController.h
//  notesnmore
//
//  Created by aashish patil on 3/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContentItem.h"
#import "AtmosUploadObjectOperation.h"
#import "dailynotesAppDelegate.h"


@interface AtmosSyncController : NSObject {

	//array of ContentItem objects
	NSArray *syncObjects;
	NSOperationQueue *syncQueue;
	id progressListener;
	
	
}

- (void) performSync;

@property (nonatomic, retain) NSOperationQueue *syncQueue;
@property (nonatomic, retain) NSArray *syncObjects;
@property (nonatomic, retain) id progressListener;

@end

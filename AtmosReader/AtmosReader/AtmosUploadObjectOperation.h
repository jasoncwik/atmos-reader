//
//  EsuUploadObjectOperation.h
//  ChirpIt
//
//  Created by neha patil on 11/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosBaseOperation.h"
#import "AtmosObject.h"
#import "SyncProgressEvent.h"


@interface AtmosUploadObjectOperation : AtmosBaseOperation {
	
	ContentItem *currentItem;
	NSString *filePath;
	
	id progressListener;
	BOOL finalOperation;
	BOOL finalSubOperation;
	
	NSInteger startRange;
	NSInteger endRange;
	
	NSInteger operationNumber;
	

}

@property (nonatomic,retain) ContentItem *currentItem;
@property (nonatomic,retain) NSString *filePath;
@property (nonatomic,retain) id progressListener;
@property (nonatomic,assign) BOOL finalOperation;
@property (nonatomic,assign) BOOL finalSubOperation;
@property (nonatomic,assign) NSInteger startRange;
@property (nonatomic,assign) NSInteger endRange;
@property (nonatomic,assign) NSInteger operationNumber;

@end

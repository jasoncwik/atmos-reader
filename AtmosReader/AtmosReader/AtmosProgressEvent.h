//
//  AtmosProgressEvent.h
//  AtmosReader
//
//  Created by Aashish Patil on 4/9/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AtmosProgressEvent : NSObject {
	
	id appData;
	
	BOOL complete; 
	BOOL failed;
	
	NSInteger totalBytes;
	NSInteger completedBytes;
	
	NSString *errorMsg;

}

@property (nonatomic,retain) id appData;
@property (nonatomic,assign) BOOL complete;
@property (nonatomic,assign) BOOL failed;
@property (nonatomic,assign) NSInteger totalBytes;
@property (nonatomic,assign) NSInteger completedBytes;
@property (nonatomic,retain) NSString *errorMsg;

@end

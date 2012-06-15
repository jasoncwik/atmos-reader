//
//  AtmosUploadOperation.h
//  AtmosReader
//
//  Created by Aashish Patil on 4/9/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosBaseOperation.h"

#define UPLOAD_MODE_CREATE 0
#define UPLOAD_MODE_UPDATE 1

/*
 Uploads one object to atmos. It can be used to either create a new object or update an existing one
 
 */
@interface AtmosUploadOperation : AtmosBaseOperation {
	
	//e.g. /photos/mygallery/myphoto.jpg
	NSString *objectPath;
	NSString *atmosId;
	NSString *localFilePath;
	
	NSData *fileData;
	
	NSInteger totalSize;
	NSInteger bufferSize;
	
	NSString *atmosResource;
	
	NSInteger numBlocks;
	NSInteger currentBlock;
	NSInteger lastBlockSize;
	
	NSInteger uploadMode; //0 = create, 1 = update
	
}

@property (nonatomic,retain) NSString *objectPath;
@property (nonatomic,retain) NSString *localFilePath;
@property (nonatomic,assign) NSInteger bufferSize;


@end

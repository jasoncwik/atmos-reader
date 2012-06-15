//
//  AtmosSyncController.m
//  notesnmore
//
//  Created by aashish patil on 3/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AtmosSyncController.h"


@implementation AtmosSyncController

@synthesize syncObjects,syncQueue,progressListener;

- (NSOperationQueue *) syncQueue {
	if(syncQueue == nil) {
		self.syncQueue = [[NSOperationQueue alloc] init];
		[self.syncQueue setMaxConcurrentOperationCount:1];
	}
	return syncQueue;
}

- (void) performSync {
	if(self.syncObjects) {
		dailynotesAppDelegate *appDel = (dailynotesAppDelegate *) [[UIApplication sharedApplication] delegate];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		NSLog(@"AtmosSyncController Found Sync Objects %d",self.syncObjects.count);
		NSInteger twork = 0;
		for(int i=0;i<self.syncObjects.count;i++) {
			ContentItem *item = (ContentItem *) [syncObjects objectAtIndex:i];
			if(item.remoteSyncStatus != REMOTE_SYNC_OK) {
				if(item.contentType == CTYPE_PICTURE || item.contentType == CTYPE_VIDEO || item.contentType == CTYPE_AUDIO) {
					
					NSLog(@"syncStatus %d %@",item.remoteSyncStatus,item.remoteId);
					NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
					NSString *docsDir = [paths objectAtIndex:0];
					NSString *fpath = [docsDir stringByAppendingPathComponent:item.contentKey];
					NSDictionary *fileMeta = [fileManager attributesOfItemAtPath:fpath error:nil];
					NSInteger fileSize = [fileMeta fileSize];
					NSLog(@"fileSize %d",fileSize);
					NSLog(@"fileBuffer %d",FILE_BUFFER);
					NSInteger numBlocks = ceil(fileSize / FILE_BUFFER);
					NSLog(@"numBlocks %d",numBlocks);
					NSInteger lastBlockSize = fileSize % FILE_BUFFER;
					NSLog(@"lastBlockSize %d",lastBlockSize);
					for(int j=0;j<numBlocks;j++) {
						AtmosUploadObjectOperation *uploadOper = [[AtmosUploadObjectOperation alloc] init];
						uploadOper.currentItem = item;
						uploadOper.filePath = fpath;
						uploadOper.progressListener = self.progressListener;
						uploadOper.startRange = j * FILE_BUFFER;
						NSLog(@"startRange %d",uploadOper.startRange);
						uploadOper.endRange = ((j+1) * FILE_BUFFER ) - 1;
						NSLog(@"endRange %d",uploadOper.endRange);
						if(item.remoteSyncStatus == REMOTE_SYNC_UNINIT || item.remoteSyncStatus == REMOTE_SYNC_SERVER_OUT_OF_SYNC) { //create new atmos object
							
							NSString *catName1 = [appDel getCategoryWithId:item.categoryId].categoryName;
							catName1 = [catName1 stringByReplacingOccurrencesOfString:@"?" withString:@"_"];
							catName1 = [catName1 stringByReplacingOccurrencesOfString:@"@" withString:@"_"];
							catName1 = [catName1 stringByReplacingOccurrencesOfString:@" " withString:@"_"];
							
							NSString *itemName = item.itemTitle;
							itemName = [itemName stringByReplacingOccurrencesOfString:@"?" withString:@"_"];
							itemName = [itemName stringByReplacingOccurrencesOfString:@"@" withString:@"_"];
							itemName = [itemName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
							
							NSString *resourceStr = [NSString stringWithFormat:@"/rest/namespace/nnm2/%@/%@.%@",catName1,itemName,item.contentFormat];
							NSLog(@"resourceStr %@",resourceStr);
							//uploadOper.atmosResource = @"/rest/objects";
							uploadOper.atmosResource = resourceStr;
							if(item.remoteSyncStatus == REMOTE_SYNC_UNINIT && j == 0) //object has never been uploaded to atmos and its the first oper
								uploadOper.httpMethod = @"POST";
							else //object has been uploaded so we are updating or its not the first oper
								uploadOper.httpMethod = @"PUT";
						} /*else { //update an existing atmos object
						   uploadOper.atmosResource = [NSString stringWithFormat:@"/rest/objects/%@",item.remoteId];
						   uploadOper.httpMethod = @"PUT";
						   }*/
						uploadOper.finalOperation = NO;
						if(lastBlockSize > 0) 
							uploadOper.finalSubOperation = NO;
						else if (j == (numBlocks -1)) 
							uploadOper.finalSubOperation = YES;
						
						uploadOper.operationNumber = (i+1) * (j + 1);
						[self.syncQueue addOperation:uploadOper];
						NSLog(@"Just added a new operation to the queue %@ %@",self.syncQueue,uploadOper);
						twork++;
					} // for(j...)
					if(lastBlockSize > 0) {
						AtmosUploadObjectOperation *uploadOper = [[AtmosUploadObjectOperation alloc] init];
						uploadOper.currentItem = item;
						uploadOper.filePath = fpath;
						uploadOper.progressListener = self.progressListener;
						uploadOper.startRange = numBlocks * FILE_BUFFER;
						uploadOper.endRange = fileSize - 1;
						if(item.remoteSyncStatus == REMOTE_SYNC_UNINIT || item.remoteSyncStatus == REMOTE_SYNC_SERVER_OUT_OF_SYNC) { //create new atmos object
							
							NSString *catName1 = [appDel getCategoryWithId:item.categoryId].categoryName;
							catName1 = [catName1 stringByReplacingOccurrencesOfString:@"?" withString:@"_"];
							catName1 = [catName1 stringByReplacingOccurrencesOfString:@"@" withString:@"_"];
							catName1 = [catName1 stringByReplacingOccurrencesOfString:@" " withString:@"_"];
							
							NSString *itemName = item.itemTitle;
							itemName = [itemName stringByReplacingOccurrencesOfString:@"?" withString:@"_"];
							itemName = [itemName stringByReplacingOccurrencesOfString:@"@" withString:@"_"];
							itemName = [itemName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
							
							NSString *resourceStr = [NSString stringWithFormat:@"/rest/namespace/nnm2/%@/%@.%@",catName1,itemName,item.contentFormat];
							NSLog(@"resourceStr %@",resourceStr);
							//uploadOper.atmosResource = @"/rest/objects";
							uploadOper.atmosResource = resourceStr;
							//
							if(numBlocks == 0 && item.remoteSyncStatus == REMOTE_SYNC_UNINIT) {
								uploadOper.httpMethod = @"POST";
							} else {
								uploadOper.httpMethod = @"PUT";
							}
							
						} /*else { //update an existing atmos object
						   uploadOper.atmosResource = [NSString stringWithFormat:@"/rest/objects/%@",item.remoteId];
						   uploadOper.httpMethod = @"PUT";
						   }*/
						
						uploadOper.finalOperation = NO;
						uploadOper.finalSubOperation = YES;
						uploadOper.operationNumber = i * (numBlocks + 1);
						[self.syncQueue addOperation:uploadOper];
						twork++;
						NSLog(@"Just added a new operation to the queue %@ %@",self.syncQueue,uploadOper);
					}
				}
				
			}
		}
		
		
		AtmosUploadObjectOperation *dbUploadOper = [[AtmosUploadObjectOperation alloc] init];
		dbUploadOper.filePath = [appDel getDBPath];
		dbUploadOper.atmosResource = @"/rest/namespace/anm/dn.sql";
		dbUploadOper.httpMethod = @"PUT";
		dbUploadOper.progressListener = self.progressListener;
		dbUploadOper.finalOperation = YES;
		[self.syncQueue addOperation:dbUploadOper];
		twork++;
		
		[self.progressListener setTotalWork:twork];
		
		
		//[self.syncQueue waitUntilAllOperationsAreFinished];
	}
	
}

@end

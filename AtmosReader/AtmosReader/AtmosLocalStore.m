//
//  AtmosLocalStore.m
//  AtmosReader
//
//  Created by Aashish Patil on 4/12/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "AtmosLocalStore.h"

@interface AtmosLocalStore (Private)

- (void)createEditableCopyOfDatabaseIfNeeded;
- (void)initializeDatabase;
- (NSOperationQueue *) getMetaSyncOperationQ;
- (NSOperationQueue *) getDownloadObjectQ;
@end

static AtmosLocalStore *sharedInstance;

@implementation AtmosLocalStore

@synthesize objectStubs, atmosCredentials, syncCompleteListener, categoryStubs;

+ (AtmosLocalStore	*) getSharedInstance {
	if(sharedInstance == nil) {
		sharedInstance = [[AtmosLocalStore alloc] init];
		[sharedInstance createEditableCopyOfDatabaseIfNeeded];
		[sharedInstance initializeDatabase];
	}
	
	return sharedInstance;
}

- (void) closeStore {
	[AtmosObject finalizeStatements];
	
	// Close the database.
	if (sqlite3_close(database) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to close database with message '%s'.", sqlite3_errmsg(database));
	}
	
}

// Creates a writable copy of the bundled default database in the application Documents directory.
- (void)createEditableCopyOfDatabaseIfNeeded {
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@DB_FILE];
    success = [fileManager fileExistsAtPath:writableDBPath];
    if (success) return;
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@DB_FILE];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
}

// Open the database connection and retrieve minimal information for all objects.
- (void)initializeDatabase {
	
	if(!database)
	{
		// The database is stored in the application bundle. 
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		NSString *path = [documentsDirectory stringByAppendingPathComponent:@DB_FILE];
		// Open the database. The database was prepared outside the application.
		if (sqlite3_open([path UTF8String], &database) != SQLITE_OK)
		{
			// Even though the open failed, call close to properly clean up resources.
			sqlite3_close(database);
			NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));
			// Additional error handling, as appropriate...
			//TODO need to shutdown app because db cannot be opened 
		}
		
	}
}

- (NSOperationQueue *) getMetaSyncOperationQ {
	if(getMetadataQ == nil) {
		getMetadataQ = [[NSOperationQueue alloc] init];
		getMetadataQ.maxConcurrentOperationCount = 1;
	} 
	return getMetadataQ;
}

- (void) performSync {
	NSLog(@"Beginning Sync. Using Credentials %@ %@ %@", self.atmosCredentials.accessPoint,self.atmosCredentials.tokenId,self.atmosCredentials.sharedSecret);
	
	//[getCategoriesOper release];
	//NSLog(@"just called getCategories Oper release");
	getCategoriesOper = [[EsuGetObjectsOperation alloc] init];
	//NSLog(@"alloced new getCategoriesOper");
	[getCategoriesOper.requestTags addObject:@"emc-dim-category-4"];
	//NSLog(@"added tag to getcategoriesoper");
	getCategoriesOper.atmosCredentials = self.atmosCredentials;
	//NSLog(@"just set atmos creds on getCategoriesOper");
	[getCategoriesOper loadAllObjects];
	//NSLog(@"called loadAllObjects");
	getCategoriesOper.completeListener = self;
	//[[self getMetaSyncOperationQ] addOperation:getCategoriesOper];
	[getCategoriesOper start];
	//NSLog(@"just added getCategoriesOper to q");
	
}

- (void) cancelSync {
	[[self getMetaSyncOperationQ] cancelAllOperations];
	
}

- (void) finishedLoadingMetadata:(id) sender {
	if(sender == getCategoriesOper) {
		//categories loaded
		[self loadCategoryStubs];
		[self resolveStubs:self.categoryStubs withRemoteObjects:getCategoriesOper.atmosObjects];
		
		//start of object sync
		//[getObjectsOper release];
		getObjectsOper = [[EsuGetObjectsOperation alloc] init];
		getObjectsOper.atmosCredentials = self.atmosCredentials;
		getObjectsOper.completeListener = self;
		[getObjectsOper.requestTags addObject:@"emc-dim-content-item-4"];
		[getObjectsOper loadAllObjects];
		[[self getMetaSyncOperationQ] addOperation:getObjectsOper];
	} else if(sender == getObjectsOper) {
		[self loadObjectStubs];
		[self resolveStubs:self.objectStubs withRemoteObjects:getObjectsOper.atmosObjects];
		
		//reload them - this is now synced data
		[self loadCategoryStubs];
		[self loadObjectStubs];
		
		[self.syncCompleteListener performSelectorOnMainThread:@selector(finishedSync) withObject:nil waitUntilDone:YES];
	}
}

/*
 Loads all objects information from the LOCAL SQLite database (not from Atmos)
 */
- (void) loadObjectStubs {
	
	if(objectStubs == nil) {
		self.objectStubs = [[NSMutableDictionary alloc] init];
	}
	
	[objectStubs removeAllObjects];
	
	const char *sql = "SELECT atmos_id from esu_objects where object_type = 0 order by last_modified desc";
	sqlite3_stmt *statement;
	
	if(sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		
		while(sqlite3_step(statement) == SQLITE_ROW) {
			const char *aid = (char *)sqlite3_column_text(statement,0);
			NSString *atmosId = [NSString stringWithUTF8String:aid];
			AtmosObject *obj = [[AtmosObject alloc] initWithAtmosId:atmosId database:database];
			[objectStubs setObject:obj forKey:atmosId];
		}
	}
	
	sqlite3_finalize(statement);
}

- (void) loadCategoryStubs {
	if(categoryStubs == nil) {
		self.categoryStubs = [[NSMutableDictionary alloc] init];
	}
	
	[categoryStubs removeAllObjects];
	
	const char *sql = "SELECT atmos_id from esu_objects where object_type = 1 order by last_modified desc";
	sqlite3_stmt *statement;
	
	if(sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		while(sqlite3_step(statement) == SQLITE_ROW) {
			const char *aid = (char *)sqlite3_column_text(statement,0);
			NSString *atmosId = [NSString stringWithUTF8String:aid];
			AtmosObject *obj = [[AtmosObject alloc] initWithAtmosId:atmosId database:database];
			[categoryStubs setObject:obj forKey:atmosId];
		}
	}
	sqlite3_finalize(statement);
}

- (NSArray *) getAllCollectionItems:(NSString *) collAtmosId {
	
	NSMutableArray *collContents = [[[NSMutableArray alloc] init] autorelease];
	NSString *sql = [NSString stringWithFormat:@"SELECT atmos_id from esu_objects where category_id = '%@' order by last_modified desc",collAtmosId];
	
	sqlite3_stmt *statement;
	if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		while(sqlite3_step(statement) == SQLITE_ROW) {
			const char *aid = (char *)sqlite3_column_text(statement,0);
			
			NSString *atmosId = [NSString stringWithUTF8String:aid];
			AtmosObject *obj = [[AtmosObject alloc] initWithAtmosId:atmosId database:database];
			[collContents addObject:obj];
		}
	}
	sqlite3_finalize(statement);
	return collContents;
}

- (NSArray *) getRecentItems:(NSInteger) sinceDays {
	
	NSMutableArray *recentItems = [[[NSMutableArray alloc] init] autorelease];
	NSDate *dt = [[NSDate alloc] init];
	NSDate *pastDate = [dt addTimeInterval:(-(sinceDays * 86400))];
	NSString *strPastDate = [AtmosObject tsToString:pastDate];
	NSString *sql = [NSString stringWithFormat:@"SELECT atmos_id from esu_objects where last_modified > '%@' and object_type = %d order by last_modified desc",strPastDate,OBJ_TYPE_CONTENTITEM];
	sqlite3_stmt *statement;
	if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		while(sqlite3_step(statement) == SQLITE_ROW) {
			const char *aid = (char *)sqlite3_column_text(statement,0);
			
			NSString *atmosId = [NSString stringWithUTF8String:aid];
			AtmosObject *obj = [[AtmosObject alloc] initWithAtmosId:atmosId database:database];
			[recentItems addObject:obj];
		}
	}
	sqlite3_finalize(statement);
	return recentItems;

}

- (NSArray *) getAllFavorites {
	NSMutableArray *recentItems = [[[NSMutableArray alloc] init] autorelease];
	NSString *sql = [NSString stringWithFormat:@"SELECT atmos_id from esu_objects where bookmark = 1 and object_type = %d order by last_modified desc",OBJ_TYPE_CONTENTITEM];
	sqlite3_stmt *statement;
	if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		while(sqlite3_step(statement) == SQLITE_ROW) {
			const char *aid = (char *)sqlite3_column_text(statement,0);
			
			NSString *atmosId = [NSString stringWithUTF8String:aid];
			AtmosObject *obj = [[AtmosObject alloc] initWithAtmosId:atmosId database:database];
			[recentItems addObject:obj];
		}
	}
	sqlite3_finalize(statement);
	return recentItems;
}

- (NSOperationQueue *) getDownloadObjectQ {
	if(downloadObjectQ == nil) {
		downloadObjectQ = [[NSOperationQueue alloc] init];
		downloadObjectQ.maxConcurrentOperationCount = 3;
	}
	return downloadObjectQ;
}

- (void) downloadObject:(AtmosObject *) atmosObj downloadListener:(id) listener {
	NSLog(@"downloadOject called %@",atmosObj.objectName);
	EsuDownloadObject *downloadOper = [[EsuDownloadObject alloc] init];
	downloadOper.atmosCredentials = self.atmosCredentials;
	downloadOper.progressListener = listener;
	//downloadOper.downloadCompleteListener = listener;
	[downloadOper downloadFile:atmosObj];
	[[self getDownloadObjectQ] addOperation:downloadOper];
	
	[downloadOper release];
	
}

/*
 Takes the remote object stubs (those loaded from Atmos) and resolves their sync status
 by comparing them with the local objects
 */
- (void) resolveStubs:(NSMutableDictionary *)localStubs withRemoteObjects:(NSMutableDictionary *) remoteObjs {
	NSArray *keys = [remoteObjs allKeys];
	for(int i= 0;i<keys.count;i++){
		NSString *key = [keys objectAtIndex:i];
		AtmosObject *obj = [remoteObjs objectForKey:key];
		AtmosObject *localObj = [localStubs objectForKey:key];
		if(localObj == nil) { //implies its a new object
			//NSLog(@"Found a new atmos object");
			[obj insertIntoDatabase:database];
			//[localStubs setObject:obj forKey:obj.atmosId];
		} else { //found a local stub
			if([obj.atmosId isEqualToString:@"4980cdb2a511106204a453410a1d1d04bcb72b2bf433"]) {
				NSLog(@"found local stub %@ %@",localObj.lastModified,obj.lastModified);
			}
			switch ([localObj.lastModified compare:obj.lastModified]){
				case NSOrderedAscending:
					//NSLog(@"NSOrderedAscending");
					break;
				case NSOrderedSame:
					//NSLog(@"NSOrderedSame");
					break;
				case NSOrderedDescending:
					//NSLog(@"NSOrderedDescending");
					break;
			}
			if([localObj.lastModified compare:obj.lastModified] != NSOrderedSame) { //remote obj was modified 
				NSLog(@"local stub modified %d ", obj.bookmark);
				localObj.lastModified = obj.lastModified;
				localObj.contentType = obj.contentType;
				localObj.objectName = obj.objectName;
				localObj.objectSize = obj.objectSize;
				localObj.categoryId = obj.categoryId;
				localObj.bookmark = obj.bookmark;
				if([localObj.lastContentModified compare:obj.lastContentModified] != NSOrderedSame) {
					localObj.syncState = STATE_OUT_OF_SYNC;
				}
				[localObj dehydrate];
			}
		}
		[localStubs removeObjectForKey:key]; //remove it so we know it was processed
	}
	
	//now remove any local objects that were not present in the cloud. It means that these were deleted
	NSArray *localKeysLeftOver = [localStubs allKeys];
	for(int i=0;i<localKeysLeftOver.count;i++) {
		NSString *delKey = [localKeysLeftOver objectAtIndex:i];
		AtmosObject *delObj = [localStubs objectForKey:delKey];
		[delObj deleteFromDatabase];
		[localStubs removeObjectForKey:delKey];
	}
	//NSLog(@"object Stubs %d",localStubs.count);
}

- (BOOL) isReachable {
	Reachability *reach = [Reachability reachabilityForInternetConnection];
	NetworkStatus nwStatus = [reach currentReachabilityStatus];
	return (nwStatus != NotReachable);
	
}


- (void) dealloc {
	[objectStubs release];
	[categoryStubs release];
	[getMetadataQ release];
	[getObjectsOper release];
	[getCategoriesOper release];
	[downloadObjectQ release];
	[super dealloc];
}


@end

//
//  AtmosLocalStore.h
//  AtmosReader
//
//  Created by Aashish Patil on 4/12/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "AtmosObject.h"
#import "EsuGetObjectsOperation.h"
#import "AtmosCredentials.h"
#import "EsuDownloadObject.h"
#import "Reachability.h"

#define DB_FILE "esu_local.sqlite"


@interface AtmosLocalStore : NSObject {
	sqlite3 *database;
	NSMutableDictionary *objectStubs;
	NSMutableDictionary *categoryStubs;
	
	EsuGetObjectsOperation *getCategoriesOper;
	EsuGetObjectsOperation *getObjectsOper;
	NSOperationQueue *getMetadataQ;
	
	NSOperationQueue *downloadObjectQ;
	
	AtmosCredentials *atmosCredentials;
	
	id syncCompleteListener;
	id downloadCompleteListener;
}

- (void) performSync;
- (void) cancelSync;

- (void) downloadObject:(AtmosObject *) obj downloadListener:(id) listener;
- (void) loadObjectStubs;
- (void) loadCategoryStubs;
- (void) resolveStubs:(NSMutableDictionary *)localStubs withRemoteObjects:(NSMutableDictionary *) remoteObjs;
- (void) closeStore;
- (NSArray *) getAllCollectionItems:(NSString *) collAtmosId;
- (NSArray *) getRecentItems:(NSInteger) sinceDays;
- (NSArray *) getAllFavorites;
- (BOOL) isReachable;

+ (AtmosLocalStore	*) getSharedInstance;


@property (nonatomic, retain) NSMutableDictionary *objectStubs;
@property (nonatomic, retain) NSMutableDictionary *categoryStubs;
@property (nonatomic, retain) AtmosCredentials *atmosCredentials;
@property (nonatomic, retain) id syncCompleteListener;

@end

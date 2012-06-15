/*
 
 Copyright (c) 2009, EMC Corporation
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 * Neither the name of the EMC Corporation nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 
 INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */



//
//  EsuObject.m
//  TestEsu
//
//  Created by aashish patil on 7/12/09.
//  Copyright 2009 EMC Corporation. All rights reserved.
//

#import "AtmosObject.h"

static sqlite3_stmt *insert_statement;
static sqlite3_stmt *delete_statement;
static sqlite3_stmt *init_statement;
static sqlite3_stmt *hydrate_statement;
static sqlite3_stmt *dehydrate_statement;

static NSDateFormatter *tsFmter;
static NSDateFormatter *friendlyDateFmter;

@implementation AtmosObject

@synthesize atmosId, objectName, filepath, lastModified, creationDate, lastContentModified, contentType, syncState, objectSize, objectType, categoryId, bookmark;

+ (void) finalizeStatements {
	
	if(insert_statement)
	{
		sqlite3_finalize(insert_statement);
		insert_statement = nil;
	}
	if(delete_statement)
	{
		sqlite3_finalize(delete_statement);
		delete_statement = nil;
	}
	if(init_statement)
	{
		sqlite3_finalize(init_statement);
		init_statement = nil;
	}
	if(hydrate_statement)
	{
		sqlite3_finalize(hydrate_statement);
		hydrate_statement = nil;
	}
	if(dehydrate_statement)
	{
		sqlite3_finalize(dehydrate_statement);
		dehydrate_statement = nil;
	}
	
}

+ (NSDate *) tsToDate: (NSString *) tsStr {
	if(tsFmter == nil) {
		tsFmter = [[NSDateFormatter alloc] init];
		[tsFmter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	}
	
	return [tsFmter dateFromString:tsStr];	
}

+ (NSString *) tsToString:(NSDate *) dtObj {
	if(tsFmter == nil) {
		tsFmter = [[NSDateFormatter alloc] init];
		[tsFmter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	}
	return [tsFmter stringFromDate:dtObj];
}

+ (NSString *) formatObjectSize:(NSInteger) objSize {
	float fSize = (float) objSize;
	if (objSize < 1023)
		return([NSString stringWithFormat:@"%dB",objSize]);
	fSize = fSize / 1024.0;
	if (fSize<1023.0)
		return([NSString stringWithFormat:@"%1.0fKB",round(fSize)]);
	fSize = fSize / 1024.0;
	if (fSize<1023.0)
		return([NSString stringWithFormat:@"%1.0fMB",round(fSize)]);
	fSize = fSize / 1024.0;
	
	return([NSString stringWithFormat:@"%1.0fGB",round(fSize)]);
}

+ (NSString *) formatFriendlyDate:(NSDate *) dtObj {	
	if(friendlyDateFmter == nil) {
		friendlyDateFmter = [[NSDateFormatter alloc] init];
		[friendlyDateFmter setDateFormat:@"MMM dd"];
	}
	
	NSTimeInterval diff = [dtObj timeIntervalSinceNow];
	diff = -diff;
	NSInteger numDays = floor(diff / 86400.0);
	NSString *strTimeInterval = nil;
	if(numDays > 0) {
		strTimeInterval = [NSString stringWithFormat:@"%d days ago",numDays];
	} else {
		NSInteger numHours = floor(diff / 3600.0);
		if(numHours > 0 ) {
			strTimeInterval = [NSString stringWithFormat:@"%d hours ago",numHours];
		} else {
			NSInteger numMins = floor(diff/60.0);	
			if(numMins > 0) {
				strTimeInterval = [NSString stringWithFormat:@"%d mins ago",numMins];
			} else {
				strTimeInterval = @"Less than a minute ago";
			}
		}
	}
	
	NSString *dtStr = [friendlyDateFmter stringFromDate:dtObj];
	NSString *retStr = [NSString stringWithFormat:@"%@, %@",dtStr,strTimeInterval];
	return retStr;
}



- (id) initWithAtmosId:(NSString *)atmosOid database:(sqlite3 *)db
{
	if(self = [super init])
	{
		self.atmosId = atmosOid;
		database = db;
		
		if(init_statement == nil)
		{
			//NSLog(@"Creating Init Statement");
			const char *sql = "SELECT last_modified, creation_date, filepath, object_name, content_type, sync_state, size, last_content_modified, object_type, category_id,bookmark from esu_objects where atmos_id = ?";
			if(sqlite3_prepare_v2(database, sql, -1, &init_statement, NULL) != SQLITE_OK)
			{
				NSAssert1(0,@"Error init_statement %s",sqlite3_errmsg(database));
			}
		}
		
		sqlite3_bind_text(init_statement,1,[atmosId UTF8String],-1,SQLITE_TRANSIENT);
		if(sqlite3_step(init_statement) == SQLITE_ROW)
		{
			
			NSString *modificationDateStr = [NSString stringWithUTF8String:(char *) sqlite3_column_text(init_statement, 0)];
			self.lastModified = [AtmosObject tsToDate:modificationDateStr];
			
			NSString *creationDateStr = [NSString stringWithUTF8String:(char *) sqlite3_column_text(init_statement,1)];
			self.creationDate = [AtmosObject tsToDate:creationDateStr];
			
			char *fp = (char *) sqlite3_column_text(init_statement,2);
			self.filepath = (fp != NULL) ? [NSString stringWithUTF8String:fp] : @"";
			
			self.objectName = [NSString stringWithUTF8String:(char *) sqlite3_column_text(init_statement,3)];
			char *contentTypeStr = (char *) sqlite3_column_text(init_statement,4);
			self.contentType = (contentTypeStr != NULL) ? [NSString stringWithUTF8String:contentTypeStr] : @"";
			self.syncState = sqlite3_column_int(init_statement, 5);
			self.objectSize = sqlite3_column_int(init_statement, 6);
			
			NSString *lastContentModifiedStr = [NSString stringWithUTF8String:(char *) sqlite3_column_text(init_statement, 7)];
			self.lastContentModified = [AtmosObject tsToDate:lastContentModifiedStr];
			
			self.objectType = sqlite3_column_int(init_statement, 8);

			char *categoryIdStr = (char *)sqlite3_column_text(init_statement, 9);
			self.categoryId = (categoryIdStr != NULL) ? [NSString stringWithUTF8String:categoryIdStr] : @"0";
			
			NSInteger nBkmark = sqlite3_column_int(init_statement, 10);
			self.bookmark = (nBkmark == 1);
			
			//self.atmosId = atmosOid;
			//NSLog(@"initWithAtmosId called %@ %@ %@",atmosOid,self.atmosId,self.objectName);
		}
		sqlite3_reset(init_statement);
		dirty = NO;
		
	}
	
	return self;
}

- (void) insertIntoDatabase:(sqlite3 *)db
{
	//NSLog(@"insertIntoDatabase called");
	database = db;
	if(insert_statement == nil)
	{	
		static char *sql = "INSERT INTO esu_objects (atmos_id,last_modified,creation_date,object_name,filepath,content_type,sync_state,size,last_content_modified,object_type,category_id,bookmark) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)";
		if(sqlite3_prepare_v2(database,sql,-1,&insert_statement,NULL) != SQLITE_OK)
		{
			NSAssert1(0,@"Error insert_statement %s",sqlite3_errmsg(database));
		}
	}
	sqlite3_bind_text(insert_statement,1,[self.atmosId UTF8String],-1,SQLITE_TRANSIENT);
	
	NSString *modDateStr = [AtmosObject tsToString:self.lastModified];
	sqlite3_bind_text(insert_statement,2,[modDateStr UTF8String],-1,SQLITE_TRANSIENT);
	
	NSString *createDateStr = [AtmosObject tsToString:self.creationDate];
	sqlite3_bind_text(insert_statement,3,[createDateStr UTF8String],-1,SQLITE_TRANSIENT);
	
	sqlite3_bind_text(insert_statement,4,[self.objectName UTF8String],-1,SQLITE_TRANSIENT);
	
	if(self.filepath == nil) 
		self.filepath = @"root";
	sqlite3_bind_text(insert_statement,5,[self.filepath UTF8String],-1,SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_statement,6,[self.contentType UTF8String],-1,SQLITE_TRANSIENT);

	sqlite3_bind_int(insert_statement,7,self.syncState);
	
	if(self.objectSize < 0)
		self.objectSize = 0;
	sqlite3_bind_int(insert_statement,8,self.objectSize);
	
	NSString *lastContentModStr = [AtmosObject tsToString:self.lastContentModified];
	sqlite3_bind_text(insert_statement, 9, [lastContentModStr UTF8String],-1,SQLITE_TRANSIENT);
	
	sqlite3_bind_int(insert_statement, 10, self.objectType);
	if(self.categoryId == nil) 
		self.categoryId = @"0";
	sqlite3_bind_text(insert_statement, 11, [self.categoryId UTF8String],-1,SQLITE_TRANSIENT);
	
	NSInteger nBm = 0;
	if(self.bookmark)
		nBm = 1;
	sqlite3_bind_int(insert_statement, 12, nBm);
	
	int success = sqlite3_step(insert_statement);

	sqlite3_reset(insert_statement);
	if(success == SQLITE_ERROR)
	{
		NSAssert1(0,@"Error: failed to insert into database %s",sqlite3_errmsg(database));
	}
	else
	{
		primaryKey = sqlite3_last_insert_rowid(database);
		NSLog(@"Inserted into database %d",primaryKey);
	}
	hydrated = YES;
}

- (void) deleteFromDatabase
{
	if(delete_statement == nil)
	{
		static char *sql = "DELETE FROM esu_objects WHERE atmos_id = ?";
		if(sqlite3_prepare_v2(database,sql,-1,&delete_statement,NULL) != SQLITE_OK)
		{
			NSAssert1(0,@"Error preparing delete SQL statement %s",sqlite3_errmsg(database));
		}
	}
	
	sqlite3_bind_text(delete_statement, 1,[self.atmosId UTF8String],-1,SQLITE_TRANSIENT );
	
	int success = sqlite3_step(delete_statement);
	sqlite3_reset(delete_statement);
	
	if(success != SQLITE_DONE)
	{
		NSAssert1(0,@"Error deleting %s",sqlite3_errmsg(database));
	}
	
}

- (void) hydrate
{
	if(hydrated) return;
	
	if(hydrate_statement == nil){
		const char *sql = "SELECT last_modified, creation_date, filepath, object_name, content_type, sync_state,size, last_content_modified, object_type, category_id,bookmark from esu_objects where atmos_id = ?";
		if(sqlite3_prepare_v2(database,sql,-1,&hydrate_statement,NULL) != SQLITE_OK) {
			NSAssert1(0,@"Error preparing statement %s",sqlite3_errmsg(database));
		}
	}
	
	sqlite3_bind_text(hydrate_statement,1,[atmosId UTF8String],-1,SQLITE_TRANSIENT);
	int success = sqlite3_step(hydrate_statement);
	if(success == SQLITE_ROW)
	{
		NSString *modificationDateStr = [NSString stringWithUTF8String:(char *) sqlite3_column_text(hydrate_statement, 0)];
		self.lastModified = [AtmosObject tsToDate:modificationDateStr];
		
		NSString *creationDateStr = [NSString stringWithUTF8String:(char *) sqlite3_column_text(hydrate_statement,1)];
		self.creationDate = [AtmosObject tsToDate:creationDateStr];
		self.filepath = [NSString stringWithUTF8String:(char *) sqlite3_column_text(hydrate_statement,2)];
		self.objectName = [NSString stringWithUTF8String:(char *) sqlite3_column_text(hydrate_statement,3)];
		self.contentType = [NSString stringWithUTF8String:(char *) sqlite3_column_text(hydrate_statement,4)];
		self.syncState = sqlite3_column_int(hydrate_statement, 5);
		self.objectSize = sqlite3_column_int(hydrate_statement,6);
		
		NSString *lastContentModStr = [NSString stringWithUTF8String:(char *) sqlite3_column_text(hydrate_statement, 7)];
		self.lastContentModified = [AtmosObject tsToDate:lastContentModStr];
		self.objectType = sqlite3_column_int(hydrate_statement, 8);
		self.categoryId = [NSString stringWithUTF8String:(char *) sqlite3_column_text(hydrate_statement, 9)];
		self.bookmark = (sqlite3_column_int(hydrate_statement, 9) == 1);
	
	}
	
	sqlite3_reset(hydrate_statement);
	
	hydrated = YES;
	
}

- (void) dehydrate
{
	if(dirty) {
		if(dehydrate_statement == nil)
		{
			static char *sql = "UPDATE esu_objects SET last_modified=?,creation_date=?,object_name=?,filepath=?,content_type=?,sync_state=?,size=?,last_content_modified=?,object_type=?, category_id=?, bookmark=? WHERE atmos_id=?";
			if(sqlite3_prepare_v2(database,sql,-1,&dehydrate_statement,NULL) != SQLITE_OK) {
				NSAssert1(0,@"Error preparing dehydrate statement %s",sqlite3_errmsg(database));
			}
		}
		
		NSString *modDateStr = [AtmosObject tsToString:self.lastModified];
		sqlite3_bind_text(dehydrate_statement,1,[modDateStr UTF8String],-1,SQLITE_TRANSIENT);
		NSString *createDateStr = [AtmosObject tsToString:self.creationDate];
		sqlite3_bind_text(dehydrate_statement,2,[createDateStr UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(dehydrate_statement,3,[self.objectName UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(dehydrate_statement,4,[self.filepath UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(dehydrate_statement,5,[self.contentType UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_int(dehydrate_statement,6,self.syncState);
		sqlite3_bind_int(dehydrate_statement,7,self.objectSize);
		NSString *lastContentModStr = [AtmosObject tsToString:self.lastContentModified];
		sqlite3_bind_text(dehydrate_statement, 8, [lastContentModStr UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_int(dehydrate_statement, 9, self.objectType);
		sqlite3_bind_text(dehydrate_statement, 10, [self.categoryId UTF8String],-1,SQLITE_TRANSIENT);
		
		NSInteger nBm = 0;
		if(self.bookmark)
			nBm = 1;
		sqlite3_bind_int(dehydrate_statement, 11, nBm);
		
		sqlite3_bind_text(dehydrate_statement,12,[self.atmosId UTF8String],-1,SQLITE_TRANSIENT);
		
		int success = sqlite3_step(dehydrate_statement);
		sqlite3_reset(dehydrate_statement);
		
		if(success != SQLITE_DONE)
		{
			NSAssert1(0,@"Error dehydrating object %s",sqlite3_errmsg(database));
		}
		
		dirty = NO;
		//NSLog(@"just dehydrated object");
	}
	hydrated = NO;
}

- (void) setAtmosId:(NSString *) aid {
	//NSLog(@"setAtmosId %@",aid);
	if(atmosId != aid && aid) {
		//NSLog(@"setAtmosId %@",aid);
		[atmosId release];
		atmosId = [aid retain];
		dirty = YES;
	}
	
}

- (void) setLastModified:(NSDate *) ld {
	
	if(lastModified != ld && ld) {
		//NSLog(@"setLastMod %@",ld);
		[lastModified release];
		lastModified = [ld retain];
		dirty = YES;
	}
}

- (void) setCreationDate:(NSDate *) cd {
	
	if(creationDate != cd && cd) {
		//NSLog(@"setCreationDate %@",cd);
		[creationDate release];
		creationDate = [cd retain];
		dirty = YES;
	}
}

- (void) setLastContentModified:(NSDate *) dt {
	if(lastContentModified != dt && dt) {
		[lastContentModified release];
		lastContentModified = [dt retain];
		dirty = YES;
	}
}

- (void) setFilepath:(NSString *) fp {
	
	if(filepath != fp && fp) {
		//NSLog(@"setFilepath %@",fp);
		[filepath release];
		filepath = [fp retain];
		dirty = YES;
	}
}

- (void) setObjectName:(NSString *) on {
	
	if(objectName != on && on) {
		//NSLog(@"setObjectName %@",on);
		[objectName release];
		objectName = [on retain];
		dirty = YES;
	}
}

- (void) setContentType:(NSString *)ctype {
	
	if(contentType != ctype && ctype) {
		//NSLog(@"setContentType %@",ctype);
		[contentType release];
		contentType = [ctype retain];
		dirty = YES;
	}
}

- (void) setSyncState:(NSInteger) ss {
	
	if(syncState != ss) {
		//NSLog(@"setSyncState called %d",ss);
		syncState = ss;
		dirty = YES;
	}
}

- (void) setObjectSize:(NSInteger) sz {
	if(objectSize != sz) {
		//NSLog(@"setSize called %d",sz);
		objectSize = sz;
		dirty = YES;
	}
}

- (void) setObjectType:(NSInteger) ot {
	if(objectType != ot) {
		objectType = ot;
		dirty = YES;
	}
}

- (void) setCategoryId:(NSString *) cid {
	if(categoryId != cid && cid) {
		[categoryId release];
		categoryId = [cid retain];
		dirty = YES;
	}
}


- (void) setBookmark:(BOOL) bm {
	if(bm != bookmark) {
		bookmark = bm;
		dirty = YES;
	}
}
	

@end

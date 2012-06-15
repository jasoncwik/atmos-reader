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
//  EsuObject.h
//  TestEsu
//
//  Created by aashish patil on 7/12/09.
//  Copyright 2009 EMC Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#define STATE_OUT_OF_SYNC 0
#define STATE_SYNCED 1
#define STATE_SYNCING 2

#define OBJ_TYPE_CONTENTITEM 0
#define OBJ_TYPE_CONTAINER 1

@interface AtmosObject : NSObject {

	NSInteger primaryKey;
	sqlite3 *database;
	BOOL hydrated;
	BOOL dirty;
	
	NSString *atmosId;
	NSString *objectName;
	NSString *filepath;
	NSDate *lastModified;
	NSDate *creationDate;
	NSDate *lastContentModified;
	NSString *contentType;
	
	BOOL bookmark;
	
	NSInteger syncState;
	
	NSInteger objectSize;
	
	NSInteger objectType;
	
	NSString *categoryId;
}

+ (void) finalizeStatements;
+ (NSDate *) tsToDate:(NSString *) tsStr;
+ (NSString *) tsToString:(NSDate *) dtObj;
+ (NSString *) formatObjectSize:(NSInteger) objSize;
+ (NSString *) formatFriendlyDate:(NSDate *) dtObj;

- (id) initWithAtmosId:(NSString *) atmosOid database:(sqlite3 *)db;
- (void) insertIntoDatabase:(sqlite3 *)database;
- (void) hydrate;
- (void) dehydrate;
- (void) deleteFromDatabase;

@property (nonatomic, retain) NSString *atmosId;
@property (nonatomic, retain) NSString *objectName;
@property (nonatomic, retain) NSString *filepath;
@property (nonatomic, retain) NSDate *lastModified;
@property (nonatomic, retain) NSDate *creationDate;
@property (nonatomic, retain) NSDate *lastContentModified;
@property (nonatomic, retain) NSString *contentType;
@property (nonatomic, assign) NSInteger syncState;
@property (nonatomic, assign) NSInteger objectSize;
@property (nonatomic, assign) NSInteger objectType;
@property (nonatomic, retain) NSString *categoryId;
@property (nonatomic, assign) BOOL bookmark;

@end

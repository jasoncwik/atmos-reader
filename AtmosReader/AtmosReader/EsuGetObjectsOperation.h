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
//  EsuGetObjectsOperation.h
//  TestEsu
//
//  Created by aashish patil on 9/7/09.
//  Copyright 2009 EMC Corporation. All rights reserved.
//
		
#import <Foundation/Foundation.h>

#import "AtmosBaseOperation.h"
#import "AtmosObject.h"

@interface EsuGetObjectsOperation : AtmosBaseOperation<NSURLConnectionDelegate> {
	
	NSMutableDictionary *atmosObjects;
	
	NSString *currentId;
	BOOL isSystemMetadata;
	BOOL isUserMetadata;
	NSXMLParser *xmlParser;
	AtmosObject *currentObject;
	NSString *currentElement;
	NSMutableString *currentValue;
	NSString *currentAtmosProp;
    NSURLConnection *conn;
	
	id completeListener;
}

- (void) loadAllObjects;

@property (nonatomic,retain) NSMutableDictionary *atmosObjects;
@property (nonatomic,retain) NSString *currentId;
@property (nonatomic,retain) NSString *currentElement;
@property (nonatomic,retain) NSString *currentAtmosProp;
@property (nonatomic,retain) NSMutableString *currentValue;
@property (nonatomic,retain) AtmosObject *currentObject;
@property (nonatomic,retain) id completeListener;
@property (nonatomic,retain) NSURLConnection *conn;


@end

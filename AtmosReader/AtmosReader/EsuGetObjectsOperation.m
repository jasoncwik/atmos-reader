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
//  EsuGetObjectsOperation.m
//  TestEsu
//
//  Created by aashish patil on 9/7/09.
//  Copyright 2009 EMC Corporation. All rights reserved.
//

#import "EsuGetObjectsOperation.h"

@interface EsuGetObjectsOperation (Private)
-(void) parseXMLData;
@end


@implementation EsuGetObjectsOperation

@synthesize atmosObjects,currentId,currentObject,currentElement,currentAtmosProp,currentValue,completeListener,conn;

- (void) loadAllObjects {
	NSString *resource = @"/rest/objects";
	self.atmosResource = resource;
}


- (void) start {
	NSMutableURLRequest *req = [super setupBaseRequestForResource:self.atmosResource];
	[req addValue:@"1" forHTTPHeaderField:@"x-emc-include-meta"];
	//[req addValue:@"emc-dim-category-1" forHTTPHeaderField:@"x-emc-tags"];
	
	//[self setMetadataOnRequest:req];
	[self setFilterTagsOnRequest:req];
	
	[super signRequest:req];
    
    [req setTimeoutInterval:30];
	
	NSDictionary *headers = [req allHTTPHeaderFields];
	NSArray *keys = [headers allKeys];
	
	for(int i=0;i<keys.count;i++) {
		NSString *strKey = (NSString *) [keys objectAtIndex:i];
		
		NSString *strVal = [headers objectForKey:strKey];
		NSLog(@"%@ = %@",strKey,strVal);
	}
    
    NSLog(@"Running request: %@", req.URL);
	self.conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES];
	
	[self willChangeValueForKey:@"isExecuting"];
	self.operExecuting = YES;
	[self didChangeValueForKey:@"isExecuting"];
	
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"willSendRequestForAuthenticationChallenge");
}

- (void) parseXMLData {
	if(xmlParser != nil) {
		[xmlParser release];
	} 
	
	xmlParser = [[NSXMLParser alloc] initWithData:self.webData];
	[xmlParser setDelegate:self];
    [xmlParser setShouldProcessNamespaces:NO];
    [xmlParser setShouldReportNamespacePrefixes:NO];
    [xmlParser setShouldResolveExternalEntities:NO];
    
    [xmlParser parse];
    
    NSError *parseError = [xmlParser parserError];
	NSLog(@"Parse Error %@",parseError);
    [xmlParser release];
}
	
	
#pragma mark NSURLRequest delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"didReceiveResponse %@",response);
	[self.webData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{	
	NSLog(@"didReceiveData %d",data.length);
	[self.webData appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// inform the user
	NSLog(@"Connection failed! Error - %@ %@",
		  [error localizedDescription],
		  [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
	
	[self willChangeValueForKey:@"isExecuting"];
	self.operExecuting = NO;
	[self didChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isFinished"];
	self.operFinished = YES;
	[self didChangeValueForKey:@"isFinished"];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *str = [[NSString alloc] initWithData:self.webData encoding:NSASCIIStringEncoding];
	NSLog(@"connectionFinishedLoading %@",str);

	[self parseXMLData];
}

-(void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	NSLog(@"Received auth challenge");
}
	
#pragma mark NSXMLParser delegate
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	NSLog(@"didstart doc");
    if(atmosObjects != nil) {
		[atmosObjects removeAllObjects];
		[atmosObjects release];
	}
	
	self.atmosObjects = [[NSMutableDictionary alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	
    if (qName) {
        elementName = qName;
    }
	
	//NSLog(@"didstartelement %@",elementName);
	//begin processing new atmos object
	if([elementName isEqualToString:@"Object"]) { 
		currentObject = [[AtmosObject alloc] init];
		NSLog(@"started new object");
	} else if([elementName isEqualToString:@"SystemMetadataList"]) {
		isSystemMetadata = YES;
		isUserMetadata = NO;
	} else if([elementName isEqualToString:@"UserMetadataList"]) {
		isUserMetadata = YES;
		isSystemMetadata = NO;
	}
	
	self.currentElement = elementName;
	self.currentValue = [NSMutableString string];
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
    if (qName) {
        elementName = qName;
    }
	
	if([elementName isEqualToString:@"Object"]) {
		if(self.currentObject != nil) {
			[self.atmosObjects setObject:self.currentObject forKey:self.currentObject.atmosId];
			//NSLog(@"Just added items %@",self.currentObject);
		}
	}
	else if([elementName isEqualToString:@"ObjectID"]) {
		//NSLog(@"Got object id %@",self.currentValue);
		
		self.currentObject.atmosId = [self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
	else if([elementName isEqualToString:@"SystemMetadataList"]) {
		isSystemMetadata = NO;
	}
	else if([elementName isEqualToString:@"UserMetadataList"]) {
		isUserMetadata = NO;
	}
	else if([elementName isEqualToString:@"Name"]) {
		//NSLog(@"Got prop name %@",self.currentValue);
		self.currentAtmosProp = [self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	} else if([elementName isEqualToString:@"Value"]) {
		//NSLog(@"Found value %@ = %@",self.currentAtmosProp,self.currentValue);
		if([self.currentAtmosProp isEqualToString:@"ctime"]) {
			NSString *s1 = [self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			NSString *s2 = [s1 stringByReplacingOccurrencesOfString:@"T" withString:@" "];
			NSString *s3 = [s2 stringByReplacingOccurrencesOfString:@"z" withString:@" "];
			NSDate *dt = [AtmosObject tsToDate:s3];
			self.currentObject.lastModified = dt;
			self.currentObject.lastContentModified = dt;
			//NSLog(@"Got modified time %@",dt);
		} else if ([self.currentAtmosProp isEqualToString:@"itime"]) {
			NSString *s1 = [self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			NSString *s2 = [s1 stringByReplacingOccurrencesOfString:@"T" withString:@" "];
			NSString *s3 = [s2 stringByReplacingOccurrencesOfString:@"z" withString:@" "];
			NSDate *dt = [AtmosObject tsToDate:s3];
			self.currentObject.creationDate = dt;
			//NSLog(@"Got creation time %@",dt);
		} /*else if ([self.currentAtmosProp isEqualToString:@"ctime"]) {
			NSString *s1 = [self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			NSString *s2 = [s1 stringByReplacingOccurrencesOfString:@"T" withString:@" "];
			NSString *s3 = [s2 stringByReplacingOccurrencesOfString:@"z" withString:@" "];
			NSDate *dt = [AtmosObject tsToDate:s3];
			self.currentObject.lastContentModified = dt;
			//NSLog(@"Got content modification time %@",dt);
		} */
		else if([self.currentAtmosProp isEqualToString:@"objectName"]) {
			self.currentObject.objectName = [self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			//NSLog(@"got objectname %@",self.currentObject.objectName);
		} else if([self.currentAtmosProp isEqualToString:@"contentFormat"]) {
			self.currentObject.contentType = [self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		} else if([self.currentAtmosProp isEqualToString:@"size"]) {
			self.currentObject.objectSize = [[self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] intValue];
			
		} else if([self.currentAtmosProp isEqualToString:@"containerId"]) {
			self.currentObject.categoryId = [self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			self.currentObject.objectType = OBJ_TYPE_CONTENTITEM;
		} else if([self.currentAtmosProp isEqualToString:@"objectType"]) {
			self.currentObject.objectType = [[self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] intValue];
		} else if([self.currentAtmosProp isEqualToString:@"favorite"]) {
			
			BOOL bmVal = NO;
			NSInteger bmValInt = [[self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] intValue];
			if(bmValInt == 1)
				bmVal = YES;
			NSLog(@"got favorite %d",bmValInt);
			self.currentObject.bookmark = bmVal;
		}	
	}
	
	//NSLog(@"currentData %@",self.currentData);
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	//NSLog(@"foundChars %@",string);
	[self.currentValue appendString:string];
	
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	//NSLog(@"didEndDocument ");
	//[localStor resolveStubs:self.atmosObjects];
	
	[self.completeListener finishedLoadingMetadata:self];
	
	[self willChangeValueForKey:@"isExecuting"];
	self.operExecuting = NO;
	[self didChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isFinished"];
	self.operFinished = YES;
	[self didChangeValueForKey:@"isFinished"];
}

#pragma mark Concurrent Operation implementation
- (BOOL)isConcurrent {
	return YES;
}

- (BOOL)isExecuting {
	return self.operExecuting;
}

- (BOOL)isFinished {
	return self.operFinished;
}


- (void) dealloc {
	[xmlParser release];
	[atmosObjects release];
    self.conn = nil;
	[super dealloc];
}


@end

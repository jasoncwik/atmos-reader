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
//  EsuDownloadObject.m
//  TestEsu
//
//  Created by aashish patil on 7/12/09.
//  Copyright 2009 EMC Corporation. All rights reserved.
//

#import "EsuDownloadObject.h"

@interface EsuDownloadObject (Private)
- (NSString *)applicationDocumentsDirectory;
@end

@implementation EsuDownloadObject

@synthesize currentObj, downloadCompleteListener;


- (void) downloadFile:(AtmosObject *) esuObj {
	NSLog(@"esuObj %@",esuObj);
	self.currentObj = esuObj;
	NSLog(@"downloadFile set current obj %@",self.currentObj);
	NSLog(@"downloadFile atmos Id is %@",self.currentObj.atmosId);
	NSString *resource = [NSString stringWithFormat:@"/rest/objects/%@",esuObj.atmosId];
	self.atmosResource = resource;
}

- (void) start {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMutableURLRequest *req = [super setupBaseRequestForResource:self.atmosResource];
	[super signRequest:req];
	NSLog(@"download request %@",req);
	bytesDownloaded = 0;
	NSURLConnection *conn = [NSURLConnection connectionWithRequest:req delegate:self];	
	
	[self willChangeValueForKey:@"isFinished"];
	self.operFinished = NO;
	[self didChangeValueForKey:@"isFinished"];
	[self willChangeValueForKey:@"isExecuting"];
	self.operExecuting = YES;
	[self didChangeValueForKey:@"isExecuting"];
	
	[pool release];
}

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"didReceiveResponse %@",response);
	[self.webData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	bytesDownloaded += data.length;
	
	AtmosProgressEvent *evt = [[AtmosProgressEvent alloc] init];
	evt.completedBytes = bytesDownloaded;
	evt.totalBytes = self.currentObj.objectSize;
	evt.complete = NO;
	evt.failed = NO;
	[self.progressListener performSelectorOnMainThread:@selector(operationProgress:) withObject:evt waitUntilDone:YES];
	[evt release];
	
	NSLog(@"didReceiveData %d",data.length);
	[self.webData appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
	NSLog(@"Connection failed! Error - %@ %@",
		  [error localizedDescription],
		  [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
	self.currentObj.syncState = STATE_OUT_OF_SYNC;
	[self.currentObj dehydrate];
	
	AtmosProgressEvent *evt = [[AtmosProgressEvent alloc] init];
	evt.failed = YES;
	evt.errorMsg = [error localizedDescription];
	[self.progressListener performSelectorOnMainThread:@selector(operationProgress:) withObject:evt waitUntilDone:YES];
	[evt release];
	
	[self willChangeValueForKey:@"isFinished"];
	self.operFinished = YES;
	[self didChangeValueForKey:@"isFinished"];
	[self willChangeValueForKey:@"isExecuting"];
	self.operExecuting = NO;
	[self didChangeValueForKey:@"isExecuting"];
	
	
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSLog(@"Finished loading ");
	
	NSString *fext = self.currentObj.contentType;
	NSString *fname = nil;
	if([fext characterAtIndex:0] == '.') {
		fname = [NSString stringWithFormat:@"%@%@",self.currentObj.atmosId,fext];
	} else {
		fname = [NSString stringWithFormat:@"%@.%@",self.currentObj.atmosId,fext];
	}
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *writableFilePath = [documentsDirectory stringByAppendingPathComponent:fname];
	NSError *err;
	[self.webData writeToFile:writableFilePath atomically:YES];
	NSLog(@"Just wrote file %@",writableFilePath);
	self.currentObj.filepath = fname;
	self.currentObj.syncState = STATE_SYNCED;
	[self.currentObj dehydrate];
	
	[self willChangeValueForKey:@"isFinished"];
	self.operFinished = YES;
	[self didChangeValueForKey:@"isFinished"];
	[self willChangeValueForKey:@"isExecuting"];
	self.operExecuting = NO;
	[self didChangeValueForKey:@"isExecuting"];
	
	AtmosProgressEvent *evt = [[AtmosProgressEvent alloc] init];
	evt.complete = YES;
	[self.progressListener performSelectorOnMainThread:@selector(operationProgress:) withObject:evt waitUntilDone:YES];
	[evt release];
	//[self.downloadCompleteListener performSelectorOnMainThread:@selector(downloadComplete) withObject:nil waitUntilDone:NO];
}

-(void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	NSLog(@"Received auth challenge");
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
	[currentObj release];
	[super dealloc];
}



@end

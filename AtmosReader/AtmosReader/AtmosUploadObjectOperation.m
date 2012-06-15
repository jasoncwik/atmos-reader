//
//  EsuUploadObjectOperation.m
//  ChirpIt
//
//  Created by aashish patil on 11/1/09.
//  Copyright 2009 Aashish Patil. All rights reserved.
//

#import "AtmosUploadObjectOperation.h"

@implementation AtmosUploadObjectOperation

@synthesize progressListener, currentItem, filePath, finalOperation, startRange, endRange, finalSubOperation,operationNumber;

- (id)init {
    self = [super init];
    if (self) {
        self.operExecuting = NO;
        self.operFinished = NO;
		self.startRange = 0;
		self.endRange = 0;
    }
    return self;
}

- (void) start {
	
	NSLog(@"start called of operation");
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableURLRequest *req = [super setupBaseRequestForResource:self.atmosResource];
	[req setHTTPMethod:self.httpMethod];
	
	NSString *listableMetaStr = [self getMetaValue:self.listableMeta];
	if(listableMetaStr && listableMetaStr.length > 0) {
		[req addValue:listableMetaStr forHTTPHeaderField:@"x-emc-listable-meta"];
	}
	
	NSString *regularMetaStr = [self getMetaValue:self.regularMeta];
	if(regularMetaStr && regularMetaStr.length > 0) {
		[req addValue:regularMetaStr forHTTPHeaderField:@"x-emc-meta"];
	}
	
	if(self.endRange > 0 && self.startRange >= 0) {
		NSString *rangeVal = [NSString stringWithFormat:@"Bytes=%d-%d",self.startRange,self.endRange];
		[req addValue:rangeVal forHTTPHeaderField:@"Range"];
	}
	
	/*NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docsDir = [paths objectAtIndex:0];
	NSString *fpath = [docsDir stringByAppendingPathComponent:contentKey];*/
	NSData *fdata = [NSData dataWithContentsOfFile:self.filePath];
	NSInteger contentLen = fdata.length;
	if(self.startRange >= 0 && self.endRange > 0) { 
		NSData *sendData = [fdata subdataWithRange:NSMakeRange(self.startRange,(self.endRange - self.startRange + 1))];
		[req setHTTPBody:sendData];
		contentLen = sendData.length;
															   
	} else {
		[req setHTTPBody:fdata];
	}
	[req setValue:[NSString stringWithFormat:@"%d",contentLen] forHTTPHeaderField:@"content-length"];
	
	[super signRequest:req withSharedSecret:[self getSharedSecret] forResource:atmosResource];
	
	NSLog(@"About to call upload request %@",req);
	/*NSString *updateMsg = nil;
	if(!self.finalOperation) {
		updateMsg = [NSString stringWithFormat:@"Uploading %@",self.currentItem.itemTitle];
	} else {
		updateMsg = @"Wrapping Up";
	}*/
	SyncProgressEvent *syncEvt = [[SyncProgressEvent alloc] init];
	syncEvt.message = self.currentItem.itemTitle;
	syncEvt.syncStatus = 0;
	syncEvt.operationNumber = self.operationNumber;
	//self.progressListener
	
	//syncEvt.totalPercentComplete
	
	[self.progressListener performSelectorOnMainThread:@selector(progressUpdate:) withObject:syncEvt waitUntilDone:YES];	
		
	if([self isCancelled]) {
		[self willChangeValueForKey:@"isFinished"];
		self.operFinished = YES;
		[self didChangeValueForKey:@"isFinished"];
		return;
	}
	
	NSURLConnection *conn = [NSURLConnection connectionWithRequest:req delegate:self];
	
	[self willChangeValueForKey:@"isExecuting"];
	self.operExecuting = YES;
	[self didChangeValueForKey:@"isExecuting"];
	
	[pool release];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if([self isCancelled]) {
		[self willChangeValueForKey:@"isExecuting"];
		self.operExecuting = NO;
		[self didChangeValueForKey:@"isExecuting"];
		
		[self willChangeValueForKey:@"isFinished"];
		self.operFinished = YES;
		[self didChangeValueForKey:@"isFinished"];
		
		return;
	
	}
	NSHTTPURLResponse *resp = (NSHTTPURLResponse *) response;
	NSLog(@"didReceiveResponse %@, %@",response,[resp allHeaderFields] );
	[self.webData setLength:0];
	NSString *atmosId = [self extractObjectId:resp];
	
	if(atmosId != nil) {
		self.currentItem.remoteId = atmosId;
		if(self.finalSubOperation)
			self.currentItem.remoteSyncStatus = REMOTE_SYNC_OK;
		else 
			self.currentItem.remoteSyncStatus = REMOTE_SYNC_SERVER_OUT_OF_SYNC;
		
		[self.currentItem dehydrate];
		NSLog(@"just dehydrated object with atmos id and updated sync status %@",atmosId);
	}
	[self willChangeValueForKey:@"isFinished"];
	self.operFinished = YES;
	[self didChangeValueForKey:@"isFinished"];
	
	[self willChangeValueForKey:@"isExecuting"];
	self.operExecuting = NO;
	[self didChangeValueForKey:@"isExecuting"];
	
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if([self isCancelled]) {
		[self willChangeValueForKey:@"isFinished"];
		self.operFinished = YES;
		[self didChangeValueForKey:@"isFinished"];
		[self willChangeValueForKey:@"isExecuting"];
		self.operExecuting = NO;
		[self didChangeValueForKey:@"isExecuting"];
		return;
	}
	
	NSLog(@"didReceiveData %d",data.length);
	[self.webData appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
	NSLog(@"Connection failed! Error - %@ %@",
		  [error localizedDescription],
		  [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);

	//[self.uploadCompleteListener newFileUploadComplete:self.contentItem.primary withAtmosId:nil withError:error];
	[self.progressListener performSelectorOnMainThread:@selector(progressUpdate:) withObject:[NSString stringWithFormat:@"Failed: %@",[error localizedDescription]] waitUntilDone:YES];
	
	[self willChangeValueForKey:@"isFinished"];
	self.operFinished = YES;
	[self didChangeValueForKey:@"isFinished"];
	[self willChangeValueForKey:@"isExecuting"];
	self.operExecuting = NO;
	[self didChangeValueForKey:@"isExecuting"];
	return;
	
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *str = [[NSString alloc] initWithData:self.webData encoding:NSASCIIStringEncoding];
	SyncProgressEvent *syncEvt = [[SyncProgressEvent alloc] init];
	syncEvt.message = self.currentItem.itemTitle;
	syncEvt.syncStatus = 1;
	syncEvt.operationNumber = self.operationNumber;
	if(self.finalOperation == YES) 
		syncEvt.totalPercentComplete = 100;
	NSLog(@"web data %@",str);
	[self.progressListener performSelectorOnMainThread:@selector(progressUpdate:) withObject:syncEvt waitUntilDone:YES];
}

-(void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	NSLog(@"Received auth challenge");
}

- (BOOL)isConcurrent {
	return YES;
}

- (BOOL)isExecuting {
	return self.operExecuting;
}

- (BOOL)isFinished {
	return self.operFinished;
}

@end

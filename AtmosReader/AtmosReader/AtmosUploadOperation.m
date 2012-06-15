//
//  AtmosUploadOperation.m
//  AtmosReader
//
//  Created by Aashish Patil on 4/9/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "AtmosUploadOperation.h"

@interface AtmosUploadOperation (Private) 

- (void) setMetadataOnRequest:(NSMutableURLRequest *) req;
- (void) sendNewRequest;

@end

@implementation AtmosUploadOperation

@synthesize objectPath,localFilePath,bufferSize;

- (id)init {
    self = [super init];
    if (self) {
        self.operExecuting = NO;
        self.operFinished = NO;
		self.bufferSize = 2 * 1024 * 1024;
		uploadMode = UPLOAD_MODE_CREATE; //default is create
		totalSize = 0;
		numBlocks = 0;
    }
    return self;
}

- (void) start {
	
	NSLog(@"start called of operation");
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	if(self.localFilePath != nil) {
		fileData = [NSData dataWithContentsOfFile:self.localFilePath];
		totalSize = fileData.length;
		numBlocks = ceil(totalSize / self.bufferSize);
		lastBlockSize = (totalSize % self.bufferSize);
	} else {
		totalSize = 0;
		numBlocks = 1;
	}
	
	currentBlock = 0;
	
	
	[self sendNewRequest];
	
	[self willChangeValueForKey:@"isExecuting"];
	self.operExecuting = YES;
	[self didChangeValueForKey:@"isExecuting"];
	
	[pool release];
}

- (void) sendNewRequest {
	
	if(self.objectPath != nil) {
		atmosResource = [NSString stringWithFormat:@"/rest/namespace%@",self.objectPath];
	} else if(atmosId != nil) {
		atmosResource = [NSString stringWithFormat:@"/rest/objects/%@",atmosId];
	} else {
		atmosResource = @"/rest/objects";
	}
	
	NSMutableURLRequest *req = [super setupBaseRequestForResource:atmosResource];
	
	if(currentBlock == 0 && uploadMode == 0) {
		[req setHTTPMethod:@"POST"];
	} else {
		[req setHTTPMethod:@"PUT"];
	}
	
	if(self.localFilePath) {
		NSInteger startRange = currentBlock * self.bufferSize;
		NSInteger endRange = (currentBlock == (numBlocks - 1)) ? (lastBlockSize - 1) : (startRange + bufferSize - 1);
		NSString *rangeVal = [NSString stringWithFormat:@"Bytes=%d-%d",startRange,endRange];
		[req addValue:rangeVal forHTTPHeaderField:@"Range"];
	
		NSData *sendData = [fileData subdataWithRange:NSMakeRange(startRange,(endRange - startRange + 1))];
		[req setHTTPBody:sendData];
	
		[req setValue:[NSString stringWithFormat:@"%d",sendData.length] forHTTPHeaderField:@"content-length"];
	}
	
	[self setMetadataOnRequest:req];
	
	[self signRequest:req];
	
	NSURLConnection *conn = [NSURLConnection connectionWithRequest:req delegate:self];
	
	
}

	
- (void) setMetadataOnRequest:(NSMutableURLRequest *) req {
	NSString *listableMetaStr = [self getMetaValue:self.listableMeta];
	if(listableMetaStr && listableMetaStr.length > 0) {
		[req addValue:listableMetaStr forHTTPHeaderField:@"x-emc-listable-meta"];
	}
	
	NSString *regularMetaStr = [self getMetaValue:self.regularMeta];
	if(regularMetaStr && regularMetaStr.length > 0) {
		[req addValue:regularMetaStr forHTTPHeaderField:@"x-emc-meta"];
	}
	
}

#pragma mark NSURLConnection delegate implementation
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSHTTPURLResponse *resp = (NSHTTPURLResponse *) response;
	NSLog(@"didReceiveResponse %@, %@",response,[resp allHeaderFields] );
	[self.webData setLength:0];
	
	if(currentBlock == 0 && uploadMode == UPLOAD_MODE_CREATE) {
		atmosId = [self extractObjectId:resp];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
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
	//[self.progressListener performSelectorOnMainThread:@selector(progressUpdate:) withObject:[NSString stringWithFormat:@"Failed: %@",[error localizedDescription]] waitUntilDone:YES];
	
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
	NSLog(@"connectionFinishedLoading %@",str);
	currentBlock++;
	if(currentBlock < numBlocks) {
		[self sendNewRequest];
	} else {
		
		NSLog(@"Upload complete with atmos id %@",atmosId);
		[self willChangeValueForKey:@"isFinished"];
		self.operFinished = YES;
		[self didChangeValueForKey:@"isFinished"];
		
		[self willChangeValueForKey:@"isExecuting"];
		self.operExecuting = NO;
		[self didChangeValueForKey:@"isExecuting"];
	}
}

-(void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	//NSLog(@"Received auth challenge");
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



@end

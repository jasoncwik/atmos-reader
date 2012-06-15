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
//  EsuHelper.m
//  TestEsu
//
//  Created by aashish patil on 7/12/09.
//  Copyright 2009 EMC Corporation. All rights reserved.
//

#import "AtmosBaseOperation.h"

//static NSString *accessPoint = @"accesspoint.atmosonline.com";
//static NSString *protocol = @"https";
//static NSString *port = @"443";

//static NSString *userSharedSecret = @"mqFx1GKzBlK5yqBWDbDqp5mEYKc=";
//static NSString *atmosUserId = @"c54faa5e354541579f59083a5b0952be/EMC00E2A4A6106011C67";

@interface AtmosBaseOperation (Private)


@end

@implementation AtmosBaseOperation

@synthesize baseUrl, webData, listableMeta, regularMeta, responseHeaders, operExecuting, operFinished;

@synthesize atmosCredentials = _atmosCredentials;
@synthesize atmosResource = _atmosResource;
@synthesize progressListener;
@synthesize appData;
@synthesize requestTags;

- (NSString *) baseUrl {
	if(baseUrl == nil) {
		baseUrl = [NSString stringWithFormat:@"%@://%@:%d",self.atmosCredentials.httpProtocol,self.atmosCredentials.accessPoint,self.atmosCredentials.portNumber];
	}
	return baseUrl;
}

- (NSMutableURLRequest *) setupBaseRequestForResource:(NSString *) resource {
	
	NSString *urlStr = [NSString stringWithFormat:@"%@%@",self.baseUrl,resource];
	urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	//NSLog(@"urlStr %@",urlStr);
	NSURL *url = [NSURL URLWithString:urlStr];
	//NSLog(@"url %@",url);
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	
	//[req addValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
	[req addValue:self.atmosCredentials.tokenId forHTTPHeaderField:@"x-emc-uid"];
	//[req addValue:@"ednSimpleApp" forHTTPHeaderField:@"x-emc-tags"];
	//[req addValue:@APP_TAG forHTTPHeaderField:@"x-emc-tags"];
	[req addValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
	
	NSTimeZone *tz = [NSTimeZone timeZoneWithName:@"GMT"];
	NSDateFormatter *fmter = [[NSDateFormatter alloc] init];
	[fmter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss z"];
	fmter.timeZone = tz;
	NSDate *now = [[NSDate alloc] init];
	NSString *fmtDate = [fmter stringFromDate:now];
	fmtDate = [fmtDate stringByReplacingOccurrencesOfString:@"+00:00" withString:@""];
	//NSLog(@"Formatted date %@",fmtDate);
	[req addValue:fmtDate forHTTPHeaderField:@"Date"];
	[fmter release];
	
	return req;
	
}


-(void) signRequest:(NSMutableURLRequest *) request {
	
	NSDictionary *headers = [request allHTTPHeaderFields];
	NSArray *keys = [headers allKeys];
	NSMutableArray *emcKeys = [[NSMutableArray alloc] init];
	for(int i=0;i<keys.count;i++) {
		NSString *strKey = (NSString *) [keys objectAtIndex:i];
		
		//NSLog(@"header %@",strKey);
		if([[strKey lowercaseString] hasPrefix:@"x-emc-"]) {
			[emcKeys addObject:strKey];
		}
	}
	NSArray *sortedEmcKeys = [emcKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	//HTTP Method
	NSMutableString *signStr = [[NSMutableString alloc] init];
	[signStr appendString:request.HTTPMethod];
	[signStr appendString:@"\n"];
	
	//Content-Type
	NSString *contentTypeVal = [headers objectForKey:@"Content-Type"];
	if(contentTypeVal != nil) {
		[signStr appendString:contentTypeVal];
	}
	[signStr appendString:@"\n"];
	
	//Range 
	NSString *rangeVal = [headers objectForKey:@"Range"];
	if(rangeVal != nil) {
		[signStr appendString:rangeVal];
	}
	[signStr appendString:@"\n"];
	
	//Date must exist since its a required field. TODO - check for non-existence of data in future
	[signStr appendString:(NSString *)[headers objectForKey:@"Date"]];
	[signStr appendString:@"\n"];
	
	//append resource
	[signStr appendString:[self.atmosResource lowercaseString]];
	[signStr appendString:@"\n"];
	
	for(int i=0;i < sortedEmcKeys.count;i++) {
		[signStr appendString:[[sortedEmcKeys objectAtIndex:i] lowercaseString]];
		[signStr appendString:@":"];
		NSString *trimmedStr = [[headers objectForKey:[sortedEmcKeys objectAtIndex:i]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSString *nlReplaced1 = [trimmedStr stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
		NSString *nlReplaced2 = [nlReplaced1 stringByReplacingOccurrencesOfString:@"\n" withString:@""];
		NSString *nlReplaced3 = [nlReplaced2 stringByReplacingOccurrencesOfString:@"\r" withString:@""];
		[signStr appendString:nlReplaced3];
		if(i < (sortedEmcKeys.count -1)) {
			[signStr appendString:@"\n"];
		}
	}
	
	NSData *keyData = [NSData dataWithBase64EncodedString:self.atmosCredentials.sharedSecret];
	NSData *clearTextData = [signStr dataUsingEncoding:NSUTF8StringEncoding];
	
	uint8_t digest[CC_SHA1_DIGEST_LENGTH] = {0};
	
	CCHmacContext hmacContext;
	CCHmacInit(&hmacContext, kCCHmacAlgSHA1, keyData.bytes, keyData.length);
	CCHmacUpdate(&hmacContext, clearTextData.bytes, clearTextData.length);
	CCHmacFinal(&hmacContext, digest);
	
	NSData *out = [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
	NSString *base64Enc = [out base64Encoding];
	//NSLog(@"signStr from method %@",signStr);
	//NSLog(@"Base 64 sig from method: %@",base64Enc);
	
	[request setValue:base64Enc forHTTPHeaderField:@"x-emc-signature"];
	
	[emcKeys release];
	[signStr release];
	
}

- (NSString *) getSharedSecret {
	return self.atmosCredentials.sharedSecret;
}

- (NSArray *) requestTags {
	if(requestTags == nil) {
		self.requestTags = [[NSMutableArray alloc] init];
	}
	return requestTags;
}

- (NSMutableDictionary *) listableMeta {
	if(listableMeta == nil) {
		self.listableMeta = [[NSMutableDictionary alloc] init];
	}
	return listableMeta;
}

- (NSMutableDictionary *)regularMeta {
	if(regularMeta == nil) {
		self.regularMeta = [[NSMutableDictionary alloc] init];
	}
	return regularMeta;
}

- (NSString *) getMetaValue: (NSMutableDictionary *) metaVals {
	NSArray *listableKeys = [metaVals allKeys];
	NSMutableString *listableMetaValue = [[[NSMutableString alloc] init] autorelease];
	NSLog(@"keyCount %d",listableKeys.count);
	for(int i=0;i<listableKeys.count;i++) {
		NSString *key = (NSString *) [listableKeys objectAtIndex:i];
		NSLog(@"got key %@",key);
		NSString *value = (NSString *) [metaVals valueForKey:key];
		[listableMetaValue appendFormat:@"%@=%@",key];
		if(i < (listableKeys.count - 1)) {
			[listableMetaValue appendString:@","];
		}
	}
	NSLog(@"listableMetaStr %@",listableMetaValue);
	return listableMetaValue;
}

- (void) setMetadataOnRequest:(NSMutableURLRequest *) req {
	
	if(self.listableMeta && self.listableMeta.count > 0) {
		NSString *listableMetaStr = [self getMetaValue:self.listableMeta];
		if(listableMetaStr && listableMetaStr.length > 0) {
			[req addValue:listableMetaStr forHTTPHeaderField:@"x-emc-listable-meta"];
		}
	}
	
	if(self.regularMeta && self.regularMeta.count > 0) {
		NSString *regularMetaStr = [self getMetaValue:self.regularMeta];
		if(regularMetaStr && regularMetaStr.length > 0) {
			[req addValue:regularMetaStr forHTTPHeaderField:@"x-emc-meta"];
		}
	}
}

- (void) setFilterTagsOnRequest:(NSMutableURLRequest *) req {
	if(self.requestTags && self.requestTags.count > 0) {
		NSMutableString *tagVal = [[NSMutableString alloc] init];
		for(int i=0;i<self.requestTags.count;i++) {
			NSString *tag = [self.requestTags objectAtIndex:i];
			[tagVal appendString:tag];
			if(i < (self.requestTags.count - 1)) {
				[tagVal appendString:@","];
			}
		}
		[req addValue:tagVal forHTTPHeaderField:@"x-emc-tags"];
	}
}


- (NSString *) extractObjectId:(NSHTTPURLResponse *) resp {
	NSDictionary *hdrFields = [resp allHeaderFields];
	NSString *locationVal = [hdrFields valueForKey:@"location"];
	if(locationVal == nil || locationVal.length == 0)
		locationVal = [hdrFields valueForKey:@"Location"];
	if(locationVal == nil || locationVal.length == 0) 
		locationVal = [hdrFields valueForKey:@"LOCATION"];
	
	NSArray *pcomps = [locationVal pathComponents];
	NSString *atmosId = (NSString *) [pcomps lastObject];
	return atmosId;
}

- (NSMutableData *) webData {
	if(webData == nil) {
		webData = [[NSMutableData alloc] init];
	}
	return webData;
}

- (void) dealloc {
	[webData release];
	[requestTags release];
	[super dealloc];
}



@end

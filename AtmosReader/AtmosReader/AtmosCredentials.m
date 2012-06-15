//
//  AtmosCredentials.m
//  AtmosReader
//
//  Created by Aashish Patil on 4/9/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "AtmosCredentials.h"


@implementation AtmosCredentials

@synthesize accessPoint = _accessPoint;
@synthesize tokenId = _tokenId;
@synthesize sharedSecret = _sharedSecret;
@synthesize httpProtocol = _httpProtocol;
@synthesize portNumber = _portNumber;

- (id)init {
    self = [super init];
    if (self) {
        self.portNumber = 80;
		self.httpProtocol = @"http";
		self.accessPoint = @"api.atmosonline.com";
	}
    return self;
}


@end

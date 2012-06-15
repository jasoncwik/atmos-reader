//
//  AtmosCredentials.h
//  AtmosReader
//
//  Created by Aashish Patil on 4/9/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AtmosCredentials : NSObject {
	
	NSString *_accessPoint; //e.g. accesspoint.atmosonline.com
	NSString *_tokenId; 
	NSString *_sharedSecret;
	NSInteger _portNumber; //e.g. 80 or 443. default is 443
	NSString *_httpProtocol; //http or https. default is https
}

@property (nonatomic,retain) NSString *accessPoint;
@property (nonatomic,retain) NSString *tokenId;
@property (nonatomic,retain) NSString *sharedSecret;
@property (nonatomic,retain) NSString *httpProtocol;
@property (nonatomic,assign) NSInteger portNumber;

@end

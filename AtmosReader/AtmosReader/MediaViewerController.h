//
//  MediaViewerController.h
//  AtmosReader
//
//  Created by Aashish Patil on 6/4/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MediaViewerController : UIViewController {
	
	IBOutlet UIWebView *webView;
	NSURL *mediaURL;

}

- (IBAction) done:(id) sender;

@property (nonatomic,retain) IBOutlet UIWebView *webView;
@property (nonatomic,retain) NSURL *mediaURL;

@end

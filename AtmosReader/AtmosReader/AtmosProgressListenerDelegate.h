//
//  AtmosProgressListenerDelegate.h
//  AtmosReader
//
//  Created by Aashish Patil on 4/9/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AtmosProgressEvent.h"

@protocol AtmosProgressListenerDelegate

- (void) operationProgress:(AtmosProgressEvent *) event;


@end

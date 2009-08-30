//
//  CBOutlineView.h
//  Cocoa Browser Air
//
//  Created by numata on 08/05/05.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CBDocument.h"


@interface CBOutlineView : NSOutlineView {
    IBOutlet CBDocument *oDocument;
}

@end

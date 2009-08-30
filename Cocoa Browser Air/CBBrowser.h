//
//  CBBrowser.h
//  Cocoa Browser Air
//
//  Created by numata on 08/05/06.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CBDocument.h"


@interface CBBrowser : NSBrowser {
    IBOutlet CBDocument *oDocument;
}

@end

//
//  CBWebView.h
//  Cocoa Browser Air
//
//  Created by numata on 08/05/07.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "CBDocument.h"


@interface CBWebView : WebView {
    IBOutlet CBDocument *oDocument;
}

@end

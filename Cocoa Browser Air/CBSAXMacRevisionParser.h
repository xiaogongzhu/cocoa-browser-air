//
//  CBSAXMacRevisionParser.h
//  Cocoa Browser Air
//
//  Created by numata on 09/03/09.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXHTMLParser.h"


@interface CBSAXMacRevisionParser : CBSAXHTMLParser {
    NSMutableString     *mHTMLSource;
    
    BOOL    mHasStarted;
}

@end


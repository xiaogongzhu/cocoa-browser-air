//
//  CBSAXMacPlatformParser.h
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXHTMLParser.h"


@interface CBSAXMacPlatformParser : CBSAXHTMLParser {
    CBNode      *mLastFoundFrameworkNode;
    
    BOOL        mIsInDocumentList;
}

@end

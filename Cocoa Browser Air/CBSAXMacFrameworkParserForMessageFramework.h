//
//  CBSAXMacFrameworkTopParserForMessageFramework.h
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXHTMLParser.h"


typedef enum {
    CBSAXMacFrameworkTopParserForMessageFrameworkStatusNone,
    CBSAXMacFrameworkTopParserForMessageFrameworkStatusH3,
    CBSAXMacFrameworkTopParserForMessageFrameworkStatusBlockquote,
    CBSAXMacFrameworkTopParserForMessageFrameworkStatusA
} CBSAXMacFrameworkTopParserForMessageFrameworkStatus;


@interface CBSAXMacFrameworkParserForMessageFramework : CBSAXHTMLParser {
    CBSAXMacFrameworkTopParserForMessageFrameworkStatus     mStatus;

    CBNode      *mReferencesNode;
    NSURL       *mClassLevelURL;
    NSString    *mClassLevelName;
}

@end


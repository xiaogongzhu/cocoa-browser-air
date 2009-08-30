//
//  CBSAXMacFrameworkParserForWSCFramework.h
//  Cocoa Browser Air
//
//  Created by numata on 09/03/28.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXHTMLParser.h"


typedef enum {
    CBSAXMacFrameworkParserForWSCParsingStatusNone,
    CBSAXMacFrameworkParserForWSCParsingStatusLink,
} CBSAXMacFrameworkParserForWSCParsingStatus;


@interface CBSAXMacFrameworkParserForWSCFramework : CBSAXHTMLParser {
    CBSAXMacFrameworkParserForWSCParsingStatus mStatus;

    MIHTMLParser    *mInnerParser;
    NSURL           *mInnerURL;

    MIHTMLParser    *mInnerParser2;
    NSURL           *mInnerURL2;

    BOOL            mIsBeforeBody;
    BOOL            mDoJump;
    
    CBNode          *mReferencesNode;
    
    NSURL           *mLinkURL;
    NSMutableString *mLinkName;
}

@end


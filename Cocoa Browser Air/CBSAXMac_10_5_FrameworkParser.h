//
//  CBSAXMacFrameworkTopParser.h
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXHTMLParser.h"


typedef enum {
    CBSAXMacFrameworkParsingStatusNone,
    CBSAXMacFrameworkParsingStatusCollectionCheck,
    CBSAXMacFrameworkParsingStatusReferences,
    CBSAXMacFrameworkParsingStatusClassLevelNameCheck,
} CBSAXMacFrameworkParsingStatus;


@interface CBSAXMac_10_5_FrameworkParser : CBSAXHTMLParser {
    CBSAXMacFrameworkParsingStatus   mStatus;
    CBSAXMacFrameworkParsingStatus   mLastRefStatus;
    
    NSMutableString     *mClassLevelName;
    CBNode              *mReferencesNode;
    NSURL               *mTargetURL;
    
    MIHTMLParser    *mInnerParser;
    NSURL           *mInnerURL;

    BOOL    mIsBeforeBody;
    BOOL    mDoJump;
}

@end


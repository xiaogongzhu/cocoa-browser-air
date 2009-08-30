//
//  CBSAXMacClassTopParser.h
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXHTMLParser.h"


@class CBNode;


typedef enum {
    CBSAXMacClassParsingStatusNone,
    CBSAXMacClassParsingStatusSpecInfo,
    CBSAXMacClassParsingStatusCategory,
    CBSAXMacClassParsingStatusMethodLevel,
    CBSAXMacClassParsingStatusFinished
} CBSAXMacClassParsingStatus;


@interface CBSAXMacClassParser : CBSAXHTMLParser {
    CBSAXMacClassParsingStatus   mStatus;
    
    MIHTMLParser    *mInnerParser;
    NSURL           *mInnerURL;
    
    NSMutableString *mTempStr;
    NSMutableString *mTempStr2;
    
    NSMutableString *mANameTags;
    BOOL    mIsAName;
    
    BOOL mIsInHeader;
    NSString    *mMethodLevelPrefix;
    
    CBNode      *mLastCategoryNode;
    
    BOOL    mIsBeforeBody;
    BOOL    mDoJump;
    BOOL    mIsInConstants;
}

@end


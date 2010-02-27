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
    CBSAXMac_10_5_ClassParsingStatusNone,
    CBSAXMac_10_5_ClassParsingStatusSpecInfo,
    CBSAXMac_10_5_ClassParsingStatusCategory,
    CBSAXMac_10_5_ClassParsingStatusMethodLevel,
    CBSAXMac_10_5_ClassParsingStatusFinished
} CBSAXMac_10_5_ClassParsingStatus;


@interface CBSAXMac_10_5_ClassParser : CBSAXHTMLParser {
    CBSAXMac_10_5_ClassParsingStatus   mStatus;
    
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
    BOOL    mIsFinished;
}

@end


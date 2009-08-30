//
//  CBSAXMacFrameworkParserForObjC_2_0.h
//  Cocoa Browser Air
//
//  Created by numata on 09/03/28.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXHTMLParser.h"


typedef enum {
    CBSAXMacFrameworkParserForObjC_2_0ParsingStatusNone,
    CBSAXMacFrameworkParserForObjC_2_0ParsingStatusSpecInfo,
    CBSAXMacFrameworkParserForObjC_2_0ParsingStatusCategory,
    CBSAXMacFrameworkParserForObjC_2_0ParsingStatusMethodLevel,
    CBSAXMacFrameworkParserForObjC_2_0ParsingStatusFinished
} CBSAXMacFrameworkParserForObjC_2_0ParsingStatus;


@interface CBSAXMacFrameworkParserForObjC_2_0 : CBSAXHTMLParser {    
    CBSAXMacFrameworkParserForObjC_2_0ParsingStatus mStatus;
    
    NSMutableString *mTempStr;
    NSMutableString *mTempStr2;

    NSMutableString *mANameTags;
    BOOL            mIsAName;
    
    BOOL            mIsInHeader;
    NSString    *mMethodLevelPrefix;

    CBNode      *mReferencesNode;
    CBNode      *mLastCategoryNode;
    CBNode      *mClassLevelNode;

    BOOL    mIsInConstants;
}

@end


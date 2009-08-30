//
//  CBSAXMacFrameworkParserForObjC_2_0.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/28.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXMacFrameworkParserForObjC_2_0.h"
#import "CBNode.h"


@implementation CBSAXMacFrameworkParserForObjC_2_0

- (void)htmlParserStart:(MIHTMLParser *)parser
{
    mStatus = CBSAXMacFrameworkParserForObjC_2_0ParsingStatusNone;
    mIsAName = NO;

    mANameTags = [[NSMutableString alloc] init];

    mReferencesNode = [[CBNode new] autorelease];
    mReferencesNode.title = @"Other References";
    mReferencesNode.isLoaded = YES;
    mReferencesNode.type = CBNodeTypeReferences;
    
    mClassLevelNode = [[CBNode new] autorelease];
    mClassLevelNode.title = @"Objective-C 2.0";
    mClassLevelNode.isLoaded = YES;
    mClassLevelNode.type = CBNodeTypeClassLevel;
    [mReferencesNode addChildNode:mClassLevelNode];
    
    [mParentNode addChildNode:mReferencesNode];
}

- (void)htmlParser:(MIHTMLParser *)parser startTag:(NSString *)tagName attributes:(NSDictionary *)attrs
{
    mIsAName = NO;
    if ([tagName isEqualToString:@"a"]) {
        if (![attrs objectForKey:@"href"]) {
            [mANameTags appendString:@"<a"];
            for (NSString *key in attrs) {
                NSString *value = [attrs objectForKey:key];
                [mANameTags appendString:@" "];
                [mANameTags appendString:key];
                [mANameTags appendString:@"=\""];
                if ([tagName isEqualToString:@"a"] && [key isEqualToString:@"href"]) {
                    NSURL *theURL = [NSURL URLWithString:value relativeToURL:mParentNode.URL];
                    [mANameTags appendString:[theURL absoluteString]];
                } else if ([tagName isEqualToString:@"img"] && [key isEqualToString:@"src"]) {
                    NSURL *theURL = [NSURL URLWithString:value relativeToURL:mParentNode.URL];
                    [mANameTags appendString:[theURL absoluteString]];
                } else {
                    [mANameTags appendString:value];
                }
                [mANameTags appendString:@"\""];
            }                
            [mANameTags appendString:@"></a>"];
            mIsAName = YES;
        }
    }
    
    if (mStatus == CBSAXMacFrameworkParserForObjC_2_0ParsingStatusNone) {
        if ([tagName isEqualToString:@"h1"]) {
            mTempStr = [[NSMutableString alloc] init];
            
            [mTempStr appendString:@"<!-- source_url=\""];
            [mTempStr appendString:[mParentNode.URL absoluteString]];
            [mTempStr appendString:@"\" -->\n"];
            
            [mTempStr appendString:@"<h1>"];
            mStatus = CBSAXMacFrameworkParserForObjC_2_0ParsingStatusSpecInfo;
        }
    }
    else if (mStatus == CBSAXMacFrameworkParserForObjC_2_0ParsingStatusSpecInfo) {
        if ([tagName isEqualToString:@"h2"]) {
            mParentNode.contentHTMLSource = mTempStr;
            [mTempStr release];
            mTempStr = nil;

            mTempStr = [[NSMutableString alloc] init];
            if ([mANameTags length] > 0) {
                [mTempStr appendString:mANameTags];
                [mTempStr appendString:@"\n"];
                [mANameTags release];
                mANameTags = [[NSMutableString alloc] init];
            }
            [mTempStr appendString:@"<h2>"];
            mTempStr2 = [[NSMutableString alloc] init];
            mIsInHeader = YES;
            mStatus = CBSAXMacFrameworkParserForObjC_2_0ParsingStatusCategory;
        } else {
            if (!mIsAName) {
                [mTempStr appendString:@"<"];
                [mTempStr appendString:tagName];
                for (NSString *key in attrs) {
                    NSString *value = [attrs objectForKey:key];
                    [mTempStr appendString:@" "];
                    [mTempStr appendString:key];
                    [mTempStr appendString:@"=\""];
                    if ([tagName isEqualToString:@"a"] && [key isEqualToString:@"href"]) {
                        NSURL *theURL = [NSURL URLWithString:value relativeToURL:mParentNode.URL];
                        [mTempStr appendString:[theURL absoluteString]];
                    } else if ([tagName isEqualToString:@"img"] && [key isEqualToString:@"src"]) {
                        NSURL *theURL = [NSURL URLWithString:value relativeToURL:mParentNode.URL];
                        [mTempStr appendString:[theURL absoluteString]];
                    } else {
                        [mTempStr appendString:value];
                    }
                    [mTempStr appendString:@"\""];
                }
                [mTempStr appendString:@">"];
            }
        }
    }
    else if (mStatus == CBSAXMacFrameworkParserForObjC_2_0ParsingStatusCategory || mStatus == CBSAXMacFrameworkParserForObjC_2_0ParsingStatusMethodLevel) {
        if ([tagName isEqualToString:@"h2"] || [tagName isEqualToString:@"h3"] || ([tagName isEqualToString:@"div"] && [[attrs objectForKey:@"class"] isEqualToString:@"mini_nav_text"])) {
            if (mStatus == CBSAXMacFrameworkParserForObjC_2_0ParsingStatusCategory) {
                CBNode *aCategoryNode = [[CBNode new] autorelease];
                aCategoryNode.title = mTempStr2;
                aCategoryNode.isLoaded = YES;
                aCategoryNode.type = CBNodeTypeCategory;
                if ([tagName isEqualToString:@"div"]) {
                    NSString *source = mTempStr;
                    int loopCount = 100;
                    while (loopCount > 0) {
                        source = [source stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        if ([source hasSuffix:@"<br><br>"]) {
                            source = [source substringToIndex:[source length] - 8];
                        } else if ([source hasSuffix:@"<br/><br/>"]) {
                            source = [source substringToIndex:[source length] - 10];
                        } else {
                            break;
                        }
                        loopCount--;
                    }
                    aCategoryNode.contentHTMLSource = source;
                } else {
                    aCategoryNode.contentHTMLSource = mTempStr;
                }
                if ([mTempStr2 isEqualToString:@"Overview"] || [mTempStr2 isEqualToString:@"Adopted Protocols"] || [mTempStr2 isEqualToString:@"Organization of This Document"] || [mTempStr2 isEqualToString:@"Result Codes"]) {
                    aCategoryNode.isLeaf = YES;
                }
                [mClassLevelNode addChildNode:aCategoryNode];
                
                mLastCategoryNode = aCategoryNode;
                if ([mTempStr2 isEqualToString:@"Class Methods"]) {
                    mMethodLevelPrefix = @"+ ";
                } else if ([mTempStr2 isEqualToString:@"Instance Methods"] || [mTempStr2 isEqualToString:@"Delegate Methods"]) {
                    mMethodLevelPrefix = @"- ";
                } else if ([mTempStr2 isEqualToString:@"Methods"]) {
                    // こうなるのはMessage フレームワークのみで、クラスメソッドしかない。
                    aCategoryNode.title = @"Class Methods";
                    mMethodLevelPrefix = @"+ ";
                } else {
                    mMethodLevelPrefix = nil;
                }
                mIsInConstants = NO;
                if ([mTempStr2 isEqualToString:@"Constants"]) {
                    mIsInConstants = YES;
                }
            } else {
                CBNode *methodLevelNode = [[CBNode new] autorelease];
                if (mMethodLevelPrefix) {
                    methodLevelNode.title = [mMethodLevelPrefix stringByAppendingString:mTempStr2];
                } else {
                    methodLevelNode.title = mTempStr2;
                }
                methodLevelNode.isLeaf = YES;
                methodLevelNode.isLoaded = YES;
                methodLevelNode.type = CBNodeTypeMethodLevel;
                if ([tagName isEqualToString:@"div"]) {
                    NSString *source = mTempStr;
                    int loopCount = 100;
                    while (loopCount > 0) {
                        source = [source stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        if ([source hasSuffix:@"<br><br>"]) {
                            source = [source substringToIndex:[source length] - 8];
                        } else if ([source hasSuffix:@"<br/><br/>"]) {
                            source = [source substringToIndex:[source length] - 10];
                        } else {
                            break;
                        }
                        loopCount--;
                    }
                    methodLevelNode.contentHTMLSource = [source stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                } else {
                    methodLevelNode.contentHTMLSource = [mTempStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
                if (![methodLevelNode.contentHTMLSource hasSuffix:@"</h3>"]) {
                    [mLastCategoryNode addChildNode:methodLevelNode];
                }                
            }
            
            [mTempStr release];
            mTempStr = nil;
            
            [mTempStr2 release];
            mTempStr2 = nil;
            
            mTempStr = [[NSMutableString alloc] init];
            mTempStr2 = [[NSMutableString alloc] init];
            mIsInHeader = YES;
            
            [mTempStr appendString:@"<!-- source_url=\""];
            [mTempStr appendString:[mParentNode.URL absoluteString]];
            [mTempStr appendString:@"\" -->\n"];
            
            if ([mANameTags length] > 0) {
                [mTempStr appendString:mANameTags];
                [mTempStr appendString:@"\n"];
                [mANameTags release];
                mANameTags = [[NSMutableString alloc] init];
            }
            
            if ([tagName isEqualToString:@"h2"]) {
                [mTempStr appendString:@"<h2>"];
                mStatus = CBSAXMacFrameworkParserForObjC_2_0ParsingStatusCategory;
            } else if ([tagName isEqualToString:@"h3"]) {
                [mTempStr appendString:@"<h3>"];
                mStatus = CBSAXMacFrameworkParserForObjC_2_0ParsingStatusMethodLevel;
            } else {
                mStatus = CBSAXMacFrameworkParserForObjC_2_0ParsingStatusFinished;
            }
        } else {
            if (!mIsAName) {
                if (![tagName isEqualToString:@"a"]) {
                    [mTempStr appendString:mANameTags];
                    [mTempStr appendString:@"\n"];
                    [mANameTags release];
                    mANameTags = [[NSMutableString alloc] init];
                }
                
                [mTempStr appendString:@"<"];
                [mTempStr appendString:tagName];
                for (NSString *key in attrs) {
                    NSString *value = [attrs objectForKey:key];
                    [mTempStr appendString:@" "];
                    [mTempStr appendString:key];
                    [mTempStr appendString:@"=\""];
                    if ([tagName isEqualToString:@"a"] && [key isEqualToString:@"href"]) {
                        NSURL *theURL = [NSURL URLWithString:value relativeToURL:mParentNode.URL];
                        [mTempStr appendString:[theURL absoluteString]];
                    } else if ([tagName isEqualToString:@"img"] && [key isEqualToString:@"src"]) {
                        NSURL *theURL = [NSURL URLWithString:value relativeToURL:mParentNode.URL];
                        [mTempStr appendString:[theURL absoluteString]];
                    } else {
                        [mTempStr appendString:value];
                    }
                    [mTempStr appendString:@"\""];
                }
                [mTempStr appendString:@">"];
            }
        }
    }
}

- (void)htmlParser:(MIHTMLParser *)parser foundText:(NSString *)text
{
    if (mStatus == CBSAXMacFrameworkParserForObjC_2_0ParsingStatusSpecInfo) {
        [mTempStr appendString:text];
    }
    else if (mStatus == CBSAXMacFrameworkParserForObjC_2_0ParsingStatusCategory || mStatus == CBSAXMacFrameworkParserForObjC_2_0ParsingStatusMethodLevel) {
        [mTempStr appendString:text];
        if (mIsInHeader) {
            [mTempStr2 appendString:text];
        }
    }
}

- (void)htmlParser:(MIHTMLParser *)parser endTag:(NSString *)tagName
{
    if (mStatus == CBSAXMacFrameworkParserForObjC_2_0ParsingStatusSpecInfo) {
        if (![tagName isEqualToString:@"br"] && (![tagName isEqualToString:@"a"] || !mIsAName)) {
            [mTempStr appendFormat:@"</%@>", tagName];
        }
    }
    else if (mStatus == CBSAXMacFrameworkParserForObjC_2_0ParsingStatusCategory || mStatus == CBSAXMacFrameworkParserForObjC_2_0ParsingStatusMethodLevel) {
        if (![tagName isEqualToString:@"br"] && (![tagName isEqualToString:@"a"] || !mIsAName)) {
            [mTempStr appendFormat:@"</%@>", tagName];
        }
        if ([tagName isEqualToString:@"h2"] || [tagName isEqualToString:@"h3"]) {
            mIsInHeader = NO;
        }
    }
}

- (void)htmlParserEnd:(MIHTMLParser *)parser
{
    if (mTempStr) {
        [mTempStr release];
        mTempStr = nil;
    }
    if (mTempStr2) {
        [mTempStr2 release];
        mTempStr2 = nil;
    }
    if (mANameTags) {
        [mANameTags release];
        mANameTags = nil;
    }
    
    for (CBNode *aCategoryNode in [mClassLevelNode childNodes]) {
        if ([aCategoryNode.title isEqualToString:@"Data Types"]) {
            [aCategoryNode sortChildNodes];
        }
    }
    
    mParentNode.isLoaded = YES;
}

@end


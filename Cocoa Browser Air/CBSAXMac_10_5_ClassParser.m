//
//  CBSAXMacClassTopParser.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXMac_10_5_ClassParser.h"
#import "CBNode.h"
#import "NSURL+RelativeAddress.h"


@implementation CBSAXMac_10_5_ClassParser

- (id)initWithParentNode:(CBNode *)parentNode
{
    self = [super initWithParentNode:parentNode];
    if (self) {
        mDoJump = NO;
        mIsBeforeBody = YES;
        mANameTags = [[NSMutableString alloc] init];
    }
    return self;
}

- (void)htmlParserStart:(MIHTMLParser *)parser
{
#if __DEBUG__
    NSLog(@"-[CBSAXMac_10_5_ClassParser htmlParserStart:]");
#endif

    mStatus = CBSAXMac_10_5_ClassParsingStatusNone;
    mMethodLevelPrefix = nil;
    mIsAName = NO;
    mIsFinished = NO;
}

- (void)htmlParser:(MIHTMLParser *)parser startTag:(NSString *)tagName attributes:(NSDictionary *)attrs
{
    if (mIsFinished) {
        return;
    }
    
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
                    NSURL *parentURL = (mInnerParser? mInnerURL: mParentNode.URL);
                    NSURL *theURL = [NSURL numataURLWithString:value relativeToURL:parentURL];
                    [mANameTags appendString:[theURL absoluteString]];
                } else if ([tagName isEqualToString:@"img"] && [key isEqualToString:@"src"]) {
                    NSURL *parentURL = (mInnerParser? mInnerURL: mParentNode.URL);
                    NSURL *theURL = [NSURL numataURLWithString:value relativeToURL:parentURL];
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
    
    // Class reference will be redirected to Reference.html from index.html by "Refresh" (except for Message Framework)
    if (mIsBeforeBody) {
        if ([tagName isEqualToString:@"meta"] && [[attrs objectForKey:@"http-equiv"] isEqualToString:@"refresh"]) {
            NSString *content = [attrs objectForKey:@"content"];
            NSRange urlRange = [content rangeOfString:@"URL="];
            if (urlRange.location != NSNotFound) {
                NSString *urlStr = [content substringFromIndex:urlRange.location + 4];
                NSURL *theURL = [NSURL numataURLWithString:urlStr relativeToURL:mParentNode.URL];
                mInnerURL = theURL;
                
                mDoJump = YES;
                
                mInnerParser = [[MIHTMLParser alloc] init];
                mInnerParser.delegate = self;
                NSData *innerData = [[NSData alloc] initWithContentsOfURL:theURL];
                [mInnerParser parseHTMLData:innerData];
                [innerData release];
                [mInnerParser release];
                mInnerParser = nil;
            }
        }
        if (mIsBeforeBody && [tagName isEqualToString:@"body"]) {
            mIsBeforeBody = NO;
        }
        return;        
    }
    
    ///// Parse Main（<body>以降）

    // <h1>タグの開始部分を見つける。
    if (mStatus == CBSAXMac_10_5_ClassParsingStatusNone) {
        if ([tagName isEqualToString:@"h1"]) {
            mTempStr = [[NSMutableString alloc] init];
            
            NSURL *parentURL = (mInnerParser? mInnerURL: mParentNode.URL);
            [mTempStr appendString:@"<!-- source_url=\""];
            [mTempStr appendString:[parentURL absoluteString]];
            [mTempStr appendString:@"\" -->\n"];
            
            [mTempStr appendString:@"<h1>"];
            mStatus = CBSAXMac_10_5_ClassParsingStatusSpecInfo;
        }
    }
    
    // 最初の<h2>タグの開始部分を見つける。
    else if (mStatus == CBSAXMac_10_5_ClassParsingStatusSpecInfo) {
        if ([tagName isEqualToString:@"h2"] || [tagName isEqualToString:@"h3"]) {
            if ([tagName isEqualToString:@"h2"]) {
                [mTempStr appendString:@"</body></html>"];
                mParentNode.contentHTMLSource = mTempStr;
                [mTempStr release];
                mTempStr = nil;
                
                mStatus = CBSAXMac_10_5_ClassParsingStatusCategory;
            } else {
                mStatus = CBSAXMac_10_5_ClassParsingStatusMethodLevel;
            }
            
            mTempStr = [[NSMutableString alloc] init];
            if ([mANameTags length] > 0) {
                [mTempStr appendString:mANameTags];
                [mTempStr appendString:@"\n"];
                [mANameTags release];
                mANameTags = [[NSMutableString alloc] init];
            }
            [mTempStr appendString:@"<"];
            [mTempStr appendString:tagName];
            [mTempStr appendString:@">"];
            mTempStr2 = [[NSMutableString alloc] init];
            mIsInHeader = YES;
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
                        NSURL *parentURL = (mInnerParser? mInnerURL: mParentNode.URL);
                        NSURL *theURL = [NSURL numataURLWithString:value relativeToURL:parentURL];
                        [mTempStr appendString:[theURL absoluteString]];
                    } else if ([tagName isEqualToString:@"img"] && [key isEqualToString:@"src"]) {
                        NSURL *parentURL = (mInnerParser? mInnerURL: mParentNode.URL);
                        NSURL *theURL = [NSURL numataURLWithString:value relativeToURL:parentURL];
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
    
    // それ以降の部分の処理
    else if (mStatus == CBSAXMac_10_5_ClassParsingStatusCategory || mStatus == CBSAXMac_10_5_ClassParsingStatusMethodLevel) {
        if ([tagName isEqualToString:@"h2"] || [tagName isEqualToString:@"h3"] || [tagName isEqualToString:@"hr"] || ([tagName isEqualToString:@"div"] && [[attrs objectForKey:@"class"] isEqualToString:@"mini_nav_text"])) {
            if (mStatus == CBSAXMac_10_5_ClassParsingStatusCategory) {
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
                    aCategoryNode.contentHTMLSource = [source stringByAppendingString:@"</body></html>"];
                } else {
                    [mTempStr appendString:@"</body></html>"];
                    aCategoryNode.contentHTMLSource = mTempStr;
                }
                if ([mTempStr2 isEqualToString:@"Overview"] || [mTempStr2 isEqualToString:@"Adopted Protocols"] || [mTempStr2 isEqualToString:@"Organization of This Document"] || [mTempStr2 isEqualToString:@"Result Codes"]) {
                    aCategoryNode.isLeaf = YES;
                }
                [mParentNode addChildNode:aCategoryNode];
                
                mLastCategoryNode = aCategoryNode;
                if ([mTempStr2 isEqualToString:@"Class Methods"]) {
                    mMethodLevelPrefix = @"+ ";
                } else if ([mTempStr2 isEqualToString:@"Instance Methods"] || [mTempStr2 isEqualToString:@"Delegate Methods"]) {
                    mMethodLevelPrefix = @"- ";
                } else if ([mTempStr2 isEqualToString:@"Methods"]) {
                    // This should be a class method in Message framework.
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
                    methodLevelNode.contentHTMLSource = [source stringByAppendingString:@"</body></html>"];
                } else {
                    [mTempStr appendString:@"</body></html>"];
                    methodLevelNode.contentHTMLSource = mTempStr;
                }
                if (mLastCategoryNode) {
                    [mLastCategoryNode addChildNode:methodLevelNode];
                } else {
                    [mParentNode addChildNode:methodLevelNode];
                }
            }
            
            [mTempStr release];
            mTempStr = nil;
            
            [mTempStr2 release];
            mTempStr2 = nil;
            
            mTempStr = [[NSMutableString alloc] init];
            mTempStr2 = [[NSMutableString alloc] init];
            mIsInHeader = YES;
            
            NSURL *parentURL = (mInnerParser? mInnerURL: mParentNode.URL);
            [mTempStr appendString:@"<!-- source_url=\""];
            [mTempStr appendString:[parentURL absoluteString]];
            [mTempStr appendString:@"\" -->\n"];
            
            if ([mANameTags length] > 0) {
                [mTempStr appendString:mANameTags];
                [mTempStr appendString:@"\n"];
                [mANameTags release];
                mANameTags = [[NSMutableString alloc] init];
            }
            
            if ([tagName isEqualToString:@"h2"]) {
                [mTempStr appendString:@"<h2>"];
                mStatus = CBSAXMac_10_5_ClassParsingStatusCategory;
            } else if ([tagName isEqualToString:@"h3"]) {
                [mTempStr appendString:@"<h3>"];
                mStatus = CBSAXMac_10_5_ClassParsingStatusMethodLevel;
            } else {
                mStatus = CBSAXMac_10_5_ClassParsingStatusFinished;
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
                        NSURL *parentURL = (mInnerParser? mInnerURL: mParentNode.URL);
                        NSURL *theURL = [NSURL numataURLWithString:value relativeToURL:parentURL];
                        [mTempStr appendString:[theURL absoluteString]];
                    } else if ([tagName isEqualToString:@"img"] && [key isEqualToString:@"src"]) {
                        NSURL *parentURL = (mInnerParser? mInnerURL: mParentNode.URL);
                        NSURL *theURL = [NSURL numataURLWithString:value relativeToURL:parentURL];
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
    if (mIsFinished) {
        return;
    }
    
    // <h1>開始から、<h2>開始までの区間。
    if (mStatus == CBSAXMac_10_5_ClassParsingStatusSpecInfo) {
        [mTempStr appendString:text];
    }
    
    // その他の区間
    else if (mStatus == CBSAXMac_10_5_ClassParsingStatusCategory || mStatus == CBSAXMac_10_5_ClassParsingStatusMethodLevel) {
        [mTempStr appendString:text];
        if (mIsInHeader) {
            [mTempStr2 appendString:text];
        }
    }
}

- (void)htmlParser:(MIHTMLParser *)parser endTag:(NSString *)tagName
{
    if (mIsFinished) {
        return;
    }
    
    if ([tagName isEqualToString:@"body"]) {
        mIsFinished = YES;
        return;
    }

    if (mStatus == CBSAXMac_10_5_ClassParsingStatusSpecInfo) {
        if (![tagName isEqualToString:@"br"] && (![tagName isEqualToString:@"a"] || !mIsAName)) {
            [mTempStr appendFormat:@"</%@>", tagName];
        }
    }
    else if (mStatus == CBSAXMac_10_5_ClassParsingStatusCategory || mStatus == CBSAXMac_10_5_ClassParsingStatusMethodLevel) {
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
    
    mParentNode.isLoaded = YES;    
}

@end



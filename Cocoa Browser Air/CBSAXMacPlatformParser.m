//
//  CBSAXMacPlatformParser.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXMacPlatformParser.h"
#import "CBNode+MacPlatformSort.h"


static NSString *sCBMacOSXCoreGraphicsFrameworkURLStr = @"file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/GraphicsImaging/Reference/CoreGraphicsReferenceCollection/index.html";
static NSString *sCBMacOSXQuartzComposerFrameworkURLStr = @"file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/GraphicsImaging/Reference/QuartzComposerRef/index.html";
static NSString *sCBMacOSXSpotlightFrameworkURLStr = @"file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/Carbon/Reference/SpotlightReference_Collection/index.html";
static NSString *sCBMacOSXImageIOFrameworkURLStr = @"file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/GraphicsImaging/Reference/ImageIORefCollection/index.html";
static NSString *sCBMacOSXCoreTextFrameworkURLStr = @"file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/Carbon/Reference/CoreText_Framework_Ref/index.html";
static NSString *sCBMacOSXImageKitFrameworkURLStr = @"file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/GraphicsImaging/Reference/ImageKitReferenceCollection/index.html";
static NSString *sCBMacOSXPDFKitFrameworkURLStr = @"file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/GraphicsImaging/Reference/PDFKit_Ref/index.html";
static NSString *sCBMacOSXCoreImageFrameworkURLStr = @"file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/GraphicsImaging/Reference/CoreImagingRef/index.html";
static NSString *sCBMacOSXCoreAnimationFrameworkURLStr = @"file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/Cocoa/Reference/CoreAnimation_framework/index.html";
static NSString *sCBMacOSXCoreFoundationFrameworkURLStr = @"file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/CoreFoundation/Reference/CoreFoundation_Collection/index.html";

/*
    Mac プラットフォームのパース手順：
        1. 「Display the document list」というコメントが来た時点でフレームワークのリストが開始します。
        2. 「〜 Framework Reference」というテキストがやってきます。
        3. その直後に <a href="...">〜</a> のタグが来ると仮定して、ノードを作成します。
        4. 何かコメントが来た時点でリストは終了します。
 */
@implementation CBSAXMacPlatformParser

- (void)htmlParserStart:(MIHTMLParser *)parser
{
    mIsInDocumentList = NO;
}

- (void)htmlParser:(MIHTMLParser *)parser foundComment:(NSString *)comment
{
    comment = [comment stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([comment isEqualToString:@"Display the document list"]) {
        mIsInDocumentList = YES;
    } else {
        mIsInDocumentList = NO;
    }
}

- (void)htmlParser:(MIHTMLParser *)parser startTag:(NSString *)tagName attributes:(NSDictionary *)attrs
{
    if (!mIsInDocumentList) {
        return;
    }
    
    if (mLastFoundFrameworkNode && [tagName isEqualToString:@"a"]) {
        NSString *hrefStr = [attrs objectForKey:@"href"];
        if (hrefStr) {
            mLastFoundFrameworkNode.URL = [[NSURL URLWithString:hrefStr relativeToURL:mParentNode.URL] standardizedURL];
            [mParentNode addChildNode:mLastFoundFrameworkNode];
            mLastFoundFrameworkNode = nil;
        }
    }
}

- (void)htmlParser:(MIHTMLParser *)parser foundText:(NSString *)text
{
    if (!mIsInDocumentList) {
        return;
    }
    
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSRange frrefRange = [text rangeOfString:@"Framework Reference"];
    if (frrefRange.location == NSNotFound) {
        return;
    }

    NSString *frameworkName = [[text substringToIndex:frrefRange.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // 「Quartz Core」フレームワークは他のフレームワークと重複するので省略する
    if ([frameworkName isEqualToString:@"Quartz Core"]) {
        return;
    }
    
    // フレームワーク・ノードの作成
    CBNode *frameworkNode = [[CBNode new] autorelease];
    frameworkNode.title = frameworkName;
    frameworkNode.isLeaf = YES;
    frameworkNode.type = CBNodeTypeFramework;
    mLastFoundFrameworkNode = frameworkNode;
}

- (void)htmlParser:(MIHTMLParser *)parser endTag:(NSString *)tagName
{
    //NSLog(@"END [%@]", tagName);
}

- (void)_addFramework:(NSString *)frameworkName URLStr:(NSString *)URLStr
{
    CBNode *aNode = [[CBNode new] autorelease];
    aNode.title = frameworkName;
    aNode.URL = [NSURL URLWithString:URLStr];
    aNode.isLeaf = YES;
    aNode.type = CBNodeTypeFramework;
    [mParentNode addChildNode:aNode];
}

- (void)htmlParserEnd:(MIHTMLParser *)parser
{
    [self _addFramework:@"Core Animation" URLStr:sCBMacOSXCoreAnimationFrameworkURLStr];
    [self _addFramework:@"Core Graphics" URLStr:sCBMacOSXCoreGraphicsFrameworkURLStr];
    [self _addFramework:@"Core Image" URLStr:sCBMacOSXCoreImageFrameworkURLStr];
    [self _addFramework:@"Core Text" URLStr:sCBMacOSXCoreTextFrameworkURLStr];
    [self _addFramework:@"Image I/O" URLStr:sCBMacOSXImageIOFrameworkURLStr];
    [self _addFramework:@"Image Kit" URLStr:sCBMacOSXImageKitFrameworkURLStr];
    [self _addFramework:@"PDF Kit" URLStr:sCBMacOSXPDFKitFrameworkURLStr];
    [self _addFramework:@"Quartz Composer" URLStr:sCBMacOSXQuartzComposerFrameworkURLStr];
    [self _addFramework:@"Spotlight" URLStr:sCBMacOSXSpotlightFrameworkURLStr];
    [self _addFramework:@"Core Foundation" URLStr:sCBMacOSXCoreFoundationFrameworkURLStr];
    
    // Objective-C 2.0 Reference の追加
    NSString *parentPath = [mParentNode.URL path];
    while (YES) {
        if ([[parentPath lastPathComponent] isEqualToString:@"Documents"]) {
            break;
        }
        parentPath = [parentPath stringByDeletingLastPathComponent];
    }
    NSString *objcRefPath = [parentPath stringByAppendingPathComponent:@"documentation/Cocoa/Reference/ObjCRuntimeRef/Reference/reference.html"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:objcRefPath]) {
        [self _addFramework:@"Objective-C 2.0" URLStr:[[NSURL fileURLWithPath:objcRefPath] absoluteString]];
    }
    
    [mParentNode sortMacFrameworkNamesAndSetImages];
    
    mParentNode.isLoaded = YES;    
}

@end


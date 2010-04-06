//
//  CBSAXMac_10_6_PlatformParser.m
//  Cocoa Browser Air
//
//  Created by numata on 09/09/04.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXMac_10_6_PlatformParser.h"
#import "CBNode+MacPlatformSort.h"
#import "CBNode+iPhonePlatformSort.h"
#import "NSString+JsonParser.h"


@implementation CBSAXMac_10_6_PlatformParser

- (NSURL *)targetURL
{
    NSString *theURLStr = [[mParentNode.URL absoluteString] stringByAppendingPathComponent:@"Contents/Resources/Documents/navigation/library.js"];
    NSURL *ret = [NSURL URLWithString:theURLStr];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[ret path]]) {
        theURLStr = [[mParentNode.URL absoluteString] stringByAppendingPathComponent:@"Contents/Resources/Documents/navigation/library.json"];
        ret = [NSURL URLWithString:theURLStr];
    }
    
    return ret;
}

- (void)addFrameworkReferenceWithTitle:(NSString *)title detailInfo:(NSDictionary *)info
{
    NSRange frrefRange = [title rangeOfString:@"Framework Reference"];
    if (frrefRange.location != NSNotFound) {
        title = [[title substringToIndex:frrefRange.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    if ([title isEqualToString:@"Application Services"]) {
        title = @"Core Graphics";
    }
    
    NSString *theURLStr = [mParentNode.URL absoluteString];
    NSString *documentPath = [info objectForKey:@"url"];
    
    NSString *documentURL = [[theURLStr stringByAppendingPathComponent:@"Contents/Resources/Documents"] stringByAppendingPathComponent:documentPath];

    // Create a framework node
    CBNode *frameworkNode = [[CBNode new] autorelease];
    frameworkNode.title = title;
    frameworkNode.isLeaf = YES;
    frameworkNode.type = CBNodeTypeFramework;
    frameworkNode.URL = [NSURL URLWithString:documentURL];

    [mParentNode addChildNode:frameworkNode];    
}

- (void)parseJavaScriptInfos:(NSDictionary *)infos
{
    NSString *theURLStr = [mParentNode.URL absoluteString];
    NSString *detailDirURLStr = [theURLStr stringByAppendingPathComponent:@"Contents/Resources/Documents/navigation/doc_details"];

    NSArray *documentInfos = [infos objectForKey:@"documents"];
    for (NSArray *anInfo in documentInfos) {
        NSString *title = [anInfo objectAtIndex:0];
        if ([title hasSuffix:@"Framework Reference"]) {
            NSString *detailFileName = [NSString stringWithFormat:@"%@.js", [anInfo objectAtIndex:1]];
            NSString *detailFileURLStr = [detailDirURLStr stringByAppendingPathComponent:detailFileName];
            NSURL *detailFileURL = [NSURL URLWithString:detailFileURLStr];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:[detailFileURL path]]) {
                NSString *detailFileName = [NSString stringWithFormat:@"%@.json", [anInfo objectAtIndex:1]];
                NSString *detailFileURLStr = [detailDirURLStr stringByAppendingPathComponent:detailFileName];
                detailFileURL = [NSURL URLWithString:detailFileURLStr];
            }
            
            NSError *error = nil;
            NSString *detailStr = [NSString stringWithContentsOfURL:detailFileURL encoding:NSUTF8StringEncoding error:&error];
            if (detailStr) {
                NSDictionary *detailInfo = [detailStr jsonObject];
                [self addFrameworkReferenceWithTitle:title detailInfo:detailInfo];
            }
        }
    }
    
    if ([mParentNode.title hasPrefix:@"iPhone"]) {
        [mParentNode sortIPhoneFrameworkNamesAndSetImages:YES];
    } else {
        [mParentNode sortMacFrameworkNamesAndSetImages];
    }

    mParentNode.isLoaded = YES;
}

@end

//
//  CBSAXIPhonePlatformParser.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXIPhonePlatformParser.h"
#import "CBNode+iPhonePlatformSort.h"


@implementation CBSAXIPhonePlatformParser

- (void)_addFramework:(NSString *)frameworkName URLStr:(NSString *)URLStr
{
    CBNode *aNode = [[CBNode new] autorelease];
    aNode.title = frameworkName;
    aNode.URL = [NSURL URLWithString:URLStr];
    aNode.isLeaf = YES;
    aNode.type = CBNodeTypeFramework;
    [mParentNode addChildNode:aNode];
}

- (void)parseJavaScriptInfos:(NSDictionary *)infos
{
    //CBNode *frameworksNode = [[CBNode new] autorelease];
    //frameworksNode.title = @"Frameworks";
    //frameworksNode.type = CBNodeTypeFrameworkFolder;

    CBNode *servicesNode = [[CBNode new] autorelease];
    servicesNode.title = @"Misc Services";
    servicesNode.isLeaf = YES;
    servicesNode.type = CBNodeTypeReferences;
    servicesNode.isLoaded = YES;

    NSString *navigationPath = [mParentNode.URL path];
    navigationPath = [navigationPath stringByDeletingLastPathComponent];
    
    CBNode *classListNode = [[CBNode new] autorelease];
    classListNode.title = @"Class References";
    for (NSString *anIndexStr in infos) {
        NSDictionary *anInfo = [infos objectForKey:anIndexStr];
        NSString *title = [anInfo objectForKey:@"title"];
        if ([title hasSuffix:@" Framework Reference"]) {
            NSString *frameworkName = [anInfo objectForKey:@"framework"];
            if ([mParentNode indexOfChildNodeWithTitle:frameworkName allowsAmbiguous:NO] >= 0) {
                continue;
            }
            if ([frameworkName isEqualToString:@"Quartz Core"]) {
                frameworkName = @"Core Animation";
            }
            
            NSString *frameworkPath = [navigationPath stringByAppendingPathComponent:[anInfo objectForKey:@"installPath"]];
            
            CBNode *frameworkNode = [[CBNode new] autorelease];
            frameworkNode.title = frameworkName;
            frameworkNode.type = CBNodeTypeFramework;
            frameworkNode.URL = [NSURL fileURLWithPath:frameworkPath];
            [mParentNode addChildNode:frameworkNode];
        }
    }
    
    //frameworksNode.isLoaded = YES;
    servicesNode.isLoaded = YES;
    
    //if ([frameworksNode childNodeCount] > 0) {
    //    [frameworksNode sortIPhoneFrameworkNamesAndSetImages];
    //    [mParentNode addChildNode:frameworksNode];
    //}
    if ([servicesNode childNodeCount] > 0) {
        [servicesNode sortIPhoneFrameworkNamesAndSetImages:NO];
        [mParentNode addChildNode:servicesNode];
    }
    
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
    
    mParentNode.isLoaded = YES;
    
    [mParentNode sortIPhoneFrameworkNamesAndSetImages:YES];
}

@end


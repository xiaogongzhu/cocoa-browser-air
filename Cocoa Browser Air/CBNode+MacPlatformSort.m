//
//  CBNode+MacPlatformSort.m
//  Cocoa Browser Air
//
//  Created by numata on 08/05/06.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import "CBNode+MacPlatformSort.h"


CBNode *_CBNodeWithTitle(NSString *title, NSArray *source);
BOOL _CBMoveNamedNodesIntoNode(CBNode *destNode, NSMutableArray *source, NSArray *names);
BOOL _CBMoveNamedNodesIntoArray(NSMutableArray *dest, NSMutableArray *source, NSArray *names);


@implementation CBNode (MacPlatformSort)

- (void)sortMacFrameworkNamesAndSetImages
{
    NSMutableArray *newChildNodes = [NSMutableArray array];
    
    // Set Images
    NSString *imageMapInfosPath = [[NSBundle mainBundle] pathForResource:@"InnerImageMap_Mac" ofType:@"plist"];
    NSDictionary *imageMap = [NSDictionary dictionaryWithContentsOfFile:imageMapInfosPath];
    
    NSString *appMapInfosPath = [[NSBundle mainBundle] pathForResource:@"AppImageMap_Mac" ofType:@"plist"];
    NSDictionary *appMap = [NSDictionary dictionaryWithContentsOfFile:appMapInfosPath];

    for (CBNode *aNode in mChildNodes) {
        if (aNode.image) {
            continue;
        }
        NSImage *image = nil;
        NSString *imageName = [imageMap objectForKey:aNode.title];
        if (imageName) {
            image = [NSImage imageNamed:imageName];
        }
        if (!image) {
            NSString *imageAppPath = [appMap objectForKey:aNode.title];
            if (imageAppPath && [[NSFileManager defaultManager] fileExistsAtPath:imageAppPath]) {
                NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
                image = [[workspace iconForFile:imageAppPath] copy];
                if ([imageAppPath hasSuffix:@"Safari.app"] || [imageAppPath hasSuffix:@"QuickTime Plaer.app"]) {
                    [image setSize:NSMakeSize(14, 14)];
                } else {
                    [image setSize:NSMakeSize(16, 16)];
                }
            }
        }
        if (!image) {
            NSString *imageAppPath = [appMap objectForKey:[aNode.title stringByAppendingString:@" 2"]];
            if (imageAppPath && [[NSFileManager defaultManager] fileExistsAtPath:imageAppPath]) {
                NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
                image = [[workspace iconForFile:imageAppPath] copy];
                if ([imageAppPath hasSuffix:@"Safari.app"] || [imageAppPath hasSuffix:@"QuickTime Plaer.app"]) {
                    [image setSize:NSMakeSize(14, 14)];
                } else {
                    [image setSize:NSMakeSize(16, 16)];
                }
            }
        }
        if (!image) {
            image = [NSImage imageNamed:@"framework_other"];
        }
        aNode.image = [image retain];
    }
    
    // Main Frameworks
    CBNode *mainFrameworksNode = [[CBNode new] autorelease];
    mainFrameworksNode.title = @"Main Frameworks";
    mainFrameworksNode.type = CBNodeTypeFrameworkFolder;
    mainFrameworksNode.isStrong = NO;
    mainFrameworksNode.parentNode = self;
    mainFrameworksNode.isLoaded = YES;
    [newChildNodes addObject:mainFrameworksNode];
    
    NSString *mainFrameworksInfosPath = [[NSBundle mainBundle] pathForResource:@"MainFrameworks_Mac" ofType:@"plist"];
    NSArray *mainFrameworks = [NSArray arrayWithContentsOfFile:mainFrameworksInfosPath];
    _CBMoveNamedNodesIntoNode(mainFrameworksNode, mChildNodes, mainFrameworks);

    // Cocoa Guides
    /*
    CBNode *documentsNode = [[CBNode new] autorelease];
    documentsNode.title = @"Documents";
    documentsNode.type = CBNodeTypeFrameworkFolder;
    documentsNode.isStrong = NO;
    documentsNode.parentNode = self;
    documentsNode.isLoaded = YES;
    [newChildNodes addObject:documentsNode];
    
    _CBMoveNamedNodesIntoNode(documentsNode, mChildNodes, [NSArray arrayWithObjects:
                                                           @"Cocoa Articles", @"Cocoa Guides", @"Cocoa Samples", nil]);
    */
    
    // Other Frameworks
    CBNode *otherFrameworksNode = [[CBNode new] autorelease];
    otherFrameworksNode.title = @"Other Frameworks";
    otherFrameworksNode.type = CBNodeTypeFrameworkFolder;
    otherFrameworksNode.isStrong = NO;
    otherFrameworksNode.parentNode = self;
    otherFrameworksNode.isLoaded = YES;
    [newChildNodes addObject:otherFrameworksNode];
    
    [mChildNodes sortUsingDescriptors:[NSArray arrayWithObject:
                                       [[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] autorelease]]];
    for (CBNode *aNode in mChildNodes) {
        [otherFrameworksNode addChildNode:aNode];
    }
    
    // Finish
    [mChildNodes release];
    mChildNodes = [newChildNodes retain];
}

@end



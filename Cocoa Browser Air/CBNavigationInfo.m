//
//  CBNavigationInfo.m
//  Cocoa Browser Air
//
//  Created by numata on 08/05/07.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import "CBNavigationInfo.h"


@implementation CBNavigationInfo

@synthesize targetName = mTargetName;
@synthesize type = mType;

- (void)dealloc
{
    [mTargetName release];

    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<CBNavigationInfo type=%d, targetName=\"%@\">", mType, mTargetName];
}

@end



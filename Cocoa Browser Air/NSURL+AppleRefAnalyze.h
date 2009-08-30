//
//  NSURL+AppleRefAnalyze.h
//  Cocoa Browser Air
//
//  Created by numata on 08/05/04.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSString+Tokenizer.h"
#import "CBReferenceInfo.h"


@interface NSURL (AppleRefAnalyze)

- (CBReferenceInfo *)makeReferenceInfo;
- (NSArray *)makeNavigationInfos;

@end


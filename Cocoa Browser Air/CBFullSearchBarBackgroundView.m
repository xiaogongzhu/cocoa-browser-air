//
//  CBFullSearchBarBackgroundView.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/29.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBFullSearchBarBackgroundView.h"


@implementation CBFullSearchBarBackgroundView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.mainColor1 = [NSColor colorWithCalibratedWhite:233/255.0f alpha:1.0];
        self.mainColor2 = [NSColor colorWithCalibratedWhite:207/255.0f alpha:1.0];
        
        self.subColor1 = [NSColor colorWithCalibratedWhite:233/255.0f alpha:1.0];
        self.subColor2 = [NSColor colorWithCalibratedWhite:207/255.0f alpha:1.0];
        
        self.mainBottomLineColor = [NSColor colorWithCalibratedWhite:177/255.0f alpha:1.0];
        self.subBottomLineColor = [NSColor colorWithCalibratedWhite:177/255.0f alpha:1.0];
        
        self.hasBottomLine = YES;
    }
    return self;
}

@end


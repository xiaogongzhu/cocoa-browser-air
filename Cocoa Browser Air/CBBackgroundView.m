//
//  CBBackgroundView.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/29.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBBackgroundView.h"


@implementation CBBackgroundView

@synthesize mainColor1 = mMainColor1;
@synthesize mainColor2 = mMainColor2;
@synthesize subColor1 = mSubColor1;
@synthesize subColor2 = mSubColor2;

@synthesize mainBottomLineColor = mMainBottomLineColor;
@synthesize subBottomLineColor = mSubBottomLineColor;
@synthesize hasBottomLine = mHasBottomLine;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.mainColor1 = [NSColor redColor];
        self.mainColor2 = [NSColor blueColor];

        self.subColor1 = [NSColor yellowColor];
        self.subColor2 = [NSColor greenColor];
        
        self.mainBottomLineColor = [NSColor colorWithCalibratedWhite:64/255.0f alpha:1.0];
        self.subBottomLineColor = [NSColor colorWithCalibratedWhite:135/255.0f alpha:1.0];
        
        self.hasBottomLine = NO;
    }
    return self;
}

- (void)dealloc
{
    [mMainColor1 release];
    [mMainColor2 release];
    [mSubColor1 release];
    [mSubColor2 release];
    
    [mMainGradient release];
    [mSubGradient release];
    
    [mMainBottomLineColor release];
    [mSubBottomLineColor release];

    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    if (!mMainGradient) {
        mMainGradient = [[NSGradient alloc] initWithStartingColor:self.mainColor1 endingColor:self.mainColor2];
        mSubGradient = [[NSGradient alloc] initWithStartingColor:self.subColor1 endingColor:self.subColor2];
    }
    
    NSRect frame = [self frame];
    frame.origin = NSZeroPoint;
    
    BOOL isMain = [[self window] isMainWindow];
    
    if (isMain) {
        [mMainGradient drawInRect:frame angle:-90.0f];
    } else {
        [mSubGradient drawInRect:frame angle:-90.0f];
    }
    
    if (self.hasBottomLine) {
        [[NSGraphicsContext currentContext] saveGraphicsState];
        [[NSGraphicsContext currentContext] setShouldAntialias:NO];
        
        if (isMain) {
            [self.mainBottomLineColor set];
        } else {
            [self.subBottomLineColor set];
        }
        NSFrameRect(NSMakeRect(0, 0, frame.size.width, 1));        
        
        [[NSGraphicsContext currentContext] restoreGraphicsState];        
    }
}

@end


//
//  CBBackgroundView.h
//  Cocoa Browser Air
//
//  Created by numata on 09/03/29.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CBBackgroundView : NSView {
    NSColor     *mMainColor1;
    NSColor     *mMainColor2;

    NSColor     *mSubColor1;
    NSColor     *mSubColor2;

    NSGradient  *mMainGradient;
    NSGradient  *mSubGradient;
    
    NSColor     *mMainBottomLineColor;
    NSColor     *mSubBottomLineColor;
    BOOL        mHasBottomLine;
}

@property(readwrite, retain) NSColor    *mainColor1;
@property(readwrite, retain) NSColor    *mainColor2;
@property(readwrite, retain) NSColor    *subColor1;
@property(readwrite, retain) NSColor    *subColor2;

@property(readwrite, retain) NSColor    *mainBottomLineColor;
@property(readwrite, retain) NSColor    *subBottomLineColor;
@property(readwrite) BOOL   hasBottomLine;

@end


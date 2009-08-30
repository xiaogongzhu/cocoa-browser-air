//
//  NSView+FadeAnimation.h
//  Cocoa Browser Air
//
//  Created by numata on 09/03/29.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSView (FadeAnimation)

- (void)fadeIn:(NSTimeInterval)duration;
- (void)fadeOut:(NSTimeInterval)duration;

@end


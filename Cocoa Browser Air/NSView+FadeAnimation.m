//
//  NSView+FadeAnimation.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/29.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "NSView+FadeAnimation.h"


@implementation NSView (FadeAnimation)

- (void)fadeIn:(NSTimeInterval)duration
{
    if (![self isHidden]) {
        return;
    }

    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject:self forKey:NSViewAnimationTargetKey];
    [dict setObject:NSViewAnimationFadeInEffect forKey:NSViewAnimationEffectKey];
    
    NSViewAnimation *anim = [[NSViewAnimation alloc]
                             initWithViewAnimations:[NSArray arrayWithObject:dict]];
    [anim setDuration:duration];
    [anim setAnimationCurve:NSAnimationEaseIn];
    
    [anim startAnimation];
    [anim release];
}

- (void)fadeOut:(NSTimeInterval)duration
{
    if ([self isHidden]) {
        return;
    }

    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject:self forKey:NSViewAnimationTargetKey];
    [dict setObject:NSViewAnimationFadeOutEffect forKey:NSViewAnimationEffectKey];
    
    NSViewAnimation *anim = [[NSViewAnimation alloc]
                             initWithViewAnimations:[NSArray arrayWithObject:dict]];
    [anim setDuration:duration];
    [anim setAnimationCurve:NSAnimationEaseIn];
    
    [anim startAnimation];
    [anim release];    
}

@end


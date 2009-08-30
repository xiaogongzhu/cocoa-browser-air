//
//  NSURL+RelativeAddress.h
//  Cocoa Browser Air
//
//  Created by numata on 09/08/31.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSURL (RelativeAddress)

+ (id)numataURLWithString:(NSString *)URLString relativeToURL:(NSURL *)baseURL;

@end




//
//  CBNavigationInfo.h
//  Cocoa Browser Air
//
//  Created by numata on 08/05/07.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef enum {
    CBNavigationTypePlatform = 0,
    CBNavigationTypeFrameworkFolder,
    CBNavigationTypeFramework,
    CBNavigationTypeReferences,
    CBNavigationTypeClassLevel,
    CBNavigationTypeCategory,
    CBNavigationTypeMethodLevel,
} CBNavigationType;


@interface CBNavigationInfo : NSObject {
    NSString            *mTargetName;
    CBNavigationType    mType;
}

@property(retain, readwrite) NSString*          targetName;
@property(assign, readwrite) CBNavigationType   type;

@end



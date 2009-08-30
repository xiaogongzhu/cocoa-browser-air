//
//  CBReferenceInfo.h
//  Cocoa Browser Air
//
//  Created by numata on 08/05/07.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CBNode.h"


typedef enum {
    CBReferenceTypeUnknown = 0,
    CBReferenceTypePlatform,
    CBReferenceTypeFramework,
    CBReferenceTypeClass,
    CBReferenceTypeClassMethod,
    CBReferenceTypeInstanceMethod,
    CBReferenceTypeDelegateMethod,
    CBReferenceTypeNotification,
    CBReferenceTypeProtocol,
    CBReferenceTypeProtocolInstanceMethod,
    CBReferenceTypeProtocolClassMethod,
    CBReferenceTypeConstantInClass,
    CBReferenceTypeConstantInProtocol,
    CBReferenceTypeProperty,
    CBReferenceTypePropertyInProtocol,
    CBReferenceTypeFunction,
    CBReferenceTypeDataType,
    CBReferenceTypeConstant,

    CBReferenceTypeCategorizedDataType,
} CBReferenceType;


/*!
    @discussion
        CBReferenceInfo is an info class, which can indicates the target node without any other infos.
        CBNavigationInfo is also an info class, but multiple infos.
 */
@interface CBReferenceInfo : NSObject {
    NSString        *mPlatformName;
    NSString        *mFrameworkName;
    NSString        *mClassName;
    NSString        *mMethodName;
    CBReferenceType mType;
}

@property(assign, readwrite) CBReferenceType    type;
@property(retain, readwrite) NSString*          platformName;
@property(retain, readwrite) NSString*          frameworkName;
@property(retain, readwrite) NSString*          className;
@property(retain, readwrite) NSString*          protocolName;
@property(retain, readwrite) NSString*          methodName;
@property(retain, readwrite) NSString*          propertyName;
@property(retain, readwrite) NSString*          variableName;
@property(retain, readwrite) NSString*          functionName;
@property(retain, readwrite) NSString*          constantName;
@property(retain, readwrite) NSString*          dataTypeName;

- (NSString *)statusText;

- (NSArray *)convertToNavigationInfos;

@end



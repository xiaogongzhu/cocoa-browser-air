//
//  CBReferenceInfo.m
//  Cocoa Browser Air
//
//  Created by numata on 08/05/07.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import "CBReferenceInfo.h"
#import "CBNavigationInfo.h"


@implementation CBReferenceInfo

#pragma mark -
#pragma mark Property Setup

@synthesize type = mType;
@synthesize platformName = mPlatformName;
@synthesize frameworkName = mFrameworkName;


/**** We set up setters/getters manually, because multiple properties cannot share one instance variable since Xcode 3.2. ****/

//@synthesize className = mClassName;
- (NSString *)className { return mClassName; }
- (void)setClassName:(NSString *)name { [mClassName release]; mClassName = [name retain]; }

//@synthesize protocolName = mClassName;
- (NSString *)protocolName { return mClassName; }
- (void)setProtocolName:(NSString *)name { [mClassName release]; mClassName = [name retain]; }

//@synthesize methodName = mMethodName;
- (NSString *)methodName { return mMethodName; }
- (void)setMethodName:(NSString *)name { [mMethodName release]; mMethodName = [name retain]; }

//@synthesize propertyName = mMethodName;
- (NSString *)propertyName { return mMethodName; }
- (void)setPropertyName:(NSString *)name { [mMethodName release]; mMethodName = [name retain]; }

//@synthesize variableName = mMethodName;
- (NSString *)variableName { return mMethodName; }
- (void)setVariableName:(NSString *)name { [mMethodName release]; mMethodName = [name retain]; }

//@synthesize functionName = mMethodName;
- (NSString *)functionName { return mMethodName; }
- (void)setFunctionName:(NSString *)name { [mMethodName release]; mMethodName = [name retain]; }

//@synthesize constantName = mMethodName;
- (NSString *)constantName { return mMethodName; }
- (void)setConstantName:(NSString *)name { [mMethodName release]; mMethodName = [name retain]; }

//@synthesize dataTypeName = mMethodName;
- (NSString *)dataTypeName { return mMethodName; }
- (void)setDataTypeName:(NSString *)name { [mMethodName release]; mMethodName = [name retain]; }


#pragma mark -
#pragma mark Initialization / Cleaning Up

- (id)init
{
    self = [super init];
    if (self) {
        mType = CBReferenceTypeUnknown;
    }
    return self;
}

- (void)dealloc
{
    [mPlatformName release];
    [mFrameworkName release];
    [mClassName release];
    [mMethodName release];
    
    [super dealloc];
}


#pragma mark -
#pragma mark Other Implementations

- (NSString *)description
{
    return [NSString stringWithFormat:@"<CBRefInfo: %@>", [self statusText]];
}

- (NSString *)statusText
{
    NSString *frameworkName = mFrameworkName;
    NSRange objcRange = [frameworkName rangeOfString:@" Objective-C"];
    if (objcRange.location != NSNotFound) {
        frameworkName = [frameworkName substringWithRange:NSMakeRange(0, objcRange.location)];
    }
    
    if (mType == CBReferenceTypeUnknown) {
        return @"show_unknown";
    } else if (mType == CBReferenceTypePlatform) {
        return [NSString stringWithFormat:NSLocalizedString(@"Show %@ platform", nil), mPlatformName];
    } else if (mType == CBReferenceTypeFramework) {
        return [NSString stringWithFormat:NSLocalizedString(@"Show %@ framework <%@>", nil), frameworkName, mPlatformName];
    } else if (mType == CBReferenceTypeClass) {
        return [NSString stringWithFormat:NSLocalizedString(@"Show %@ class (%@) <%@>", nil), mClassName, frameworkName, mPlatformName];
    } else if (mType == CBReferenceTypeProtocol) {
        return [NSString stringWithFormat:NSLocalizedString(@"Show %@ protocol (%@) <%@>", nil), mClassName, frameworkName, mPlatformName];
    } else if (mType == CBReferenceTypeClassMethod) {
        return [NSString stringWithFormat:NSLocalizedString(@"Show + [%@ %@] method (%@) <%@>", nil), mClassName, mMethodName, frameworkName, mPlatformName];
    } else if (mType == CBReferenceTypeInstanceMethod) {
        return [NSString stringWithFormat:NSLocalizedString(@"Show - [%@ %@] method (%@) <%@>", nil), mClassName, mMethodName, frameworkName, mPlatformName];
    } else if (mType == CBReferenceTypeDelegateMethod) {
        return [NSString stringWithFormat:NSLocalizedString(@"Show - [%@ %@] delegate method (%@) <%@>", nil), mClassName, mMethodName, frameworkName, mPlatformName];
    } else if (mType == CBReferenceTypeProperty) {
        return [NSString stringWithFormat:NSLocalizedString(@"Show %@.%@ property (%@) <%@>", nil), mClassName, mMethodName, frameworkName, mPlatformName];
    } else if (mType == CBReferenceTypeProtocolClassMethod) {
        return [NSString stringWithFormat:NSLocalizedString(@"Show + [%@ %@] protocol class method (%@) <%@>", nil), mClassName, mMethodName, frameworkName, mPlatformName];
    } else if (mType == CBReferenceTypeProtocolInstanceMethod) {
        return [NSString stringWithFormat:NSLocalizedString(@"Show - [%@ %@] protocol instance method (%@) <%@>", nil), mClassName, mMethodName, frameworkName, mPlatformName];
    } else if (mType == CBReferenceTypeConstantInProtocol) {
        return [NSString stringWithFormat:NSLocalizedString(@"Show constant %@ in %@ protocol (%@) <%@>", nil), mMethodName, mClassName, frameworkName, mPlatformName];
    } else if (mType == CBReferenceTypePropertyInProtocol) {
        return [NSString stringWithFormat:NSLocalizedString(@"Show property %@ in %@ protocol (%@) <%@>", nil), mMethodName, mClassName, frameworkName, mPlatformName];
    } else if (mType == CBReferenceTypeFunction) {
        return [NSString stringWithFormat:NSLocalizedString(@"Show function %@ (%@) <%@>", nil), mMethodName, frameworkName, mPlatformName];
    } else if (mType == CBReferenceTypeDataType) {
        return [NSString stringWithFormat:NSLocalizedString(@"Show data type %@ (%@) <%@>", nil), mMethodName, frameworkName, mPlatformName];
    } else if (mType == CBReferenceTypeConstant) {
        return [NSString stringWithFormat:NSLocalizedString(@"Show global constant %@ (%@) <%@>", nil), mMethodName, frameworkName, mPlatformName];
    }
    return @"----";
}

- (NSString *)frameworkFolderNameForFramework:(NSString *)frameworkName platformName:(NSString *)platformName
{
    NSArray *mainFrameworkNames = nil;
    if ([platformName hasPrefix:@"iPhone"] || [platformName hasPrefix:@"iOS"]) {
        NSString *mainFrameworksInfosPath = [[NSBundle mainBundle] pathForResource:@"MainFrameworks_iPhone" ofType:@"plist"];
        mainFrameworkNames = [NSArray arrayWithContentsOfFile:mainFrameworksInfosPath];
    } else {
        NSString *mainFrameworksInfosPath = [[NSBundle mainBundle] pathForResource:@"MainFrameworks_Mac" ofType:@"plist"];
        mainFrameworkNames = [NSArray arrayWithContentsOfFile:mainFrameworksInfosPath];
    }
    if ([mainFrameworkNames containsObject:frameworkName]) {
        return @"Main Frameworks";
    }
    return @"Other Frameworks";
}

- (NSArray *)convertToNavigationInfos
{
    NSMutableArray *stack = [NSMutableArray array];

    // TODO: Manage Global Constants
    
    // Method Level and Category Level
    if (mType == CBReferenceTypeClassMethod || mType == CBReferenceTypeInstanceMethod ||
        mType == CBReferenceTypeProtocolClassMethod || mType == CBReferenceTypeProtocolInstanceMethod ||
        mType == CBReferenceTypeProperty || mType == CBReferenceTypeConstantInClass ||
        mType == CBReferenceTypeDataType || mType == CBReferenceTypeFunction ||
        mType == CBReferenceTypePropertyInProtocol || mType == CBReferenceTypeConstantInProtocol ||
        mType == CBReferenceTypeConstant || mType == CBReferenceTypeCategorizedDataType)
    {
        CBNavigationInfo *methodLevelNavi = [[CBNavigationInfo new] autorelease];
        methodLevelNavi.type = CBNavigationTypeMethodLevel;
        methodLevelNavi.targetName = mMethodName;
        if (mType == CBReferenceTypeClassMethod || mType == CBReferenceTypeProtocolClassMethod) {
            if (![methodLevelNavi.targetName hasPrefix:@"+ "]) {
                methodLevelNavi.targetName = [@"+ " stringByAppendingString:methodLevelNavi.targetName];
            }
        } else if (mType == CBReferenceTypeInstanceMethod || mType == CBReferenceTypeProtocolInstanceMethod) {
            if (![methodLevelNavi.targetName hasPrefix:@"- "]) {
                methodLevelNavi.targetName = [@"- " stringByAppendingString:methodLevelNavi.targetName];
            }
        }
        [stack addObject:methodLevelNavi];
        
        CBNavigationInfo *categoryLevelNavi = [[CBNavigationInfo new] autorelease];
        categoryLevelNavi.type = CBNavigationTypeCategory;
        if (mType == CBReferenceTypeClassMethod || mType == CBReferenceTypeProtocolClassMethod) {
            categoryLevelNavi.targetName = @"Class Methods";
        } else if (mType == CBReferenceTypeInstanceMethod || mType == CBReferenceTypeProtocolInstanceMethod) {
            categoryLevelNavi.targetName = @"Instance Methods";
        } else if (mType == CBReferenceTypeProperty || mType == CBReferenceTypePropertyInProtocol) {
            categoryLevelNavi.targetName = @"Properties";
        } else if (mType == CBReferenceTypeDataType || mType == CBReferenceTypeCategorizedDataType) {
            categoryLevelNavi.targetName = @"Data Types";
        } else if (mType == CBReferenceTypeFunction) {
            categoryLevelNavi.targetName = @"Functions";
        } else {
            categoryLevelNavi.targetName = @"Constants";
        }
        [stack addObject:categoryLevelNavi];
    }
    
    // Class Level
    if (mType == CBReferenceTypeClass || mType == CBReferenceTypeClassMethod ||
        mType == CBReferenceTypeInstanceMethod || mType == CBReferenceTypeProtocolClassMethod ||
        mType == CBReferenceTypeProtocolInstanceMethod || mType == CBReferenceTypeConstantInClass ||
        mType == CBReferenceTypeProperty || mType == CBReferenceTypeProtocol ||
        mType == CBReferenceTypeDataType || mType == CBReferenceTypeFunction ||
        mType == CBReferenceTypePropertyInProtocol || mType == CBReferenceTypeConstantInProtocol ||
        mType == CBReferenceTypeConstant || mType == CBReferenceTypeCategorizedDataType)
    {
        CBNavigationInfo *classLevelNavi = [[CBNavigationInfo new] autorelease];
        classLevelNavi.type = CBNavigationTypeClassLevel;
        if (mType == CBReferenceTypeDataType) {
            if ([mFrameworkName isEqualToString:@"Objective-C 2.0"]) {
                classLevelNavi.targetName = @"Objective-C 2.0";
            } else {
                classLevelNavi.targetName = @"Data Types";
            }
        } else if (mType == CBReferenceTypeFunction) {
            classLevelNavi.targetName = @"Functions";
        } else if (mType == CBReferenceTypeConstant) {
            classLevelNavi.targetName = @"Constants";
        } else {
            classLevelNavi.targetName = self.className;
        }
        [stack addObject:classLevelNavi];
    }
    
    // References
    if (mType == CBReferenceTypeClass || mType == CBReferenceTypeClassMethod ||
        mType == CBReferenceTypeInstanceMethod || mType == CBReferenceTypeProtocolClassMethod ||
        mType == CBReferenceTypeProtocolInstanceMethod || mType == CBReferenceTypeConstantInClass ||
        mType == CBReferenceTypeProperty || mType == CBReferenceTypeProtocol ||
        mType == CBReferenceTypeConstant || mType == CBReferenceTypeFunction || mType == CBReferenceTypeDataType ||
        mType == CBReferenceTypePropertyInProtocol || mType == CBReferenceTypeConstantInProtocol ||
        mType == CBReferenceTypeCategorizedDataType)
    {
        CBNavigationInfo *referencesNavi = [[CBNavigationInfo new] autorelease];
        referencesNavi.type = CBNavigationTypeReferences;
        if (mType == CBReferenceTypeProtocol || mType == CBReferenceTypeProtocolClassMethod ||
            mType == CBReferenceTypeProtocolInstanceMethod || mType == CBReferenceTypePropertyInProtocol ||
            mType == CBReferenceTypeConstantInProtocol)
        {
            referencesNavi.targetName = @"Protocol References";
        } else if (mType == CBReferenceTypeConstant || mType == CBReferenceTypeFunction || mType == CBReferenceTypeDataType || mType == CBReferenceTypeCategorizedDataType) {
            if (mType == CBReferenceTypeCategorizedDataType && [mFrameworkName isEqualToString:@"Core Foundation"]) {
                referencesNavi.targetName = @"Opaque Type References";
            } else {
                referencesNavi.targetName = @"Other References";
            }
        } else {
            if ([mFrameworkName isEqualToString:@"Objective-C 2.0"]) {
                referencesNavi.targetName = @"Other References";
            } else {
                referencesNavi.targetName = @"Class References";
            }
        }
        [stack addObject:referencesNavi];
    }
    
    // Framework
    CBNavigationInfo *frameworkNavi = [[CBNavigationInfo new] autorelease];
    frameworkNavi.type = CBNavigationTypeFramework;
    frameworkNavi.targetName = mFrameworkName;
    [stack addObject:frameworkNavi];
    
    // Framework Folder
    CBNavigationInfo *frameworkFolderNavi = [[CBNavigationInfo new] autorelease];
    frameworkFolderNavi.type = CBNavigationTypeFrameworkFolder;
    frameworkFolderNavi.targetName = [self frameworkFolderNameForFramework:mFrameworkName platformName:mPlatformName];
    [stack addObject:frameworkFolderNavi];
    
    // Platform
    CBNavigationInfo *platformNavi = [[CBNavigationInfo new] autorelease];
    platformNavi.type = CBNavigationTypePlatform;
    platformNavi.targetName = mPlatformName;
    [stack addObject:platformNavi];
    
    return stack;
}

@end



//
//  NSObject+ObjectMap.h
//
//  Created by Benjamin Gordon on 5/8/13.
//  Copyright (c) 2013 Matthew York. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonKeyDerivation.h>
#import <Security/SecRandom.h>

#define OMDateFormat @"yyyy-MM-dd HH:mm:ss.S"
#define OMTimeZone @"UTC"

typedef void(^SaveFileBlock)(NSError *error);
typedef void(^LoadFileBlock)(id object, NSError *error);

@interface NSObject (ObjectIO)

//Save files
-(void)saveToUrl:(NSURL *)url completion:(SaveFileBlock)completion;
-(void)saveToUrl:(NSURL *)url reducedFileSize:(BOOL)reducedSize completion:(SaveFileBlock)completion;
-(void)saveToUrl:(NSURL *)url reducedFileSize:(BOOL)reducedSize password:(NSString *)password salt:(NSString *)salt completion:(SaveFileBlock)completion;
-(void)saveToDocumentsDirectoryWithName:(NSString *)filename completion:(SaveFileBlock)completion;
-(void)saveToDocumentsDirectoryWithName:(NSString *)filename reducedFileSize:(BOOL)reducedFileSize password:(NSString *)password  salt:(NSString *)salt completion:(SaveFileBlock)completion;

//Load files
-(void)loadFromUrl:(NSURL *)url completion:(LoadFileBlock)completion;
-(void)loadFromUrl:(NSURL *)url password:(NSString *)password salt:(NSString *)salt completion:(LoadFileBlock)completion;
-(void)loadFromDocumentsDirectoryWithName:(NSString *)filename completion:(LoadFileBlock)completion;
-(void)loadFromDocumentsDirectoryWithName:(NSString *)filename password:(NSString *)password salt:(NSString *)salt completion:(LoadFileBlock)completion;

// Base64 Encode/Decode (helper)
+(NSString *)encodeBase64WithData:(NSData *)objData;
+(NSData *)base64DataFromString:(NSString *)string;

// Helpers
+(NSString *)generateSalt;

@end


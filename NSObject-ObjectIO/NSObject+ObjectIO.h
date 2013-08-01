//  Copyright (c) 2012 The Board of Trustees of The University of Alabama
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  3. Neither the name of the University nor the names of the contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
//  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//   SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
//  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
//  OF THE POSSIBILITY OF SUCH DAMAGE.

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


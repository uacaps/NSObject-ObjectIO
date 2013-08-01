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

#import "NSObject+ObjectIO.h"

#define kChunkSizeBytes (1024 * 1024) // 1 MB

static const char _base64EncodingTable[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const short _base64DecodingTable[256] = {
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -2, -1, -1, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, -2, -2, 63,
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, -2, -2, -2,
    -2,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, -2,
    -2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2
};


@implementation NSObject (ObjectIO)

const NSUInteger kPBKDFRounds = 10000;

#pragma mark - Save Files
-(void)saveToUrl:(NSURL *)url completion:(SaveFileBlock)completion{
    [self saveToUrl:url reducedFileSize:NO password:nil salt:nil completion:^(NSError *error) {
        completion(error);
    }];
}

-(void)saveToUrl:(NSURL *)url reducedFileSize:(BOOL)reducedSize completion:(SaveFileBlock)completion{
    [self saveToUrl:url reducedFileSize:reducedSize password:nil salt:nil completion:^(NSError *error) {
        completion(error);
    }];
}

-(void)saveToDocumentsDirectoryWithName:(NSString *)filename completion:(SaveFileBlock)completion{
    [self saveToDocumentsDirectoryWithName:filename reducedFileSize:NO password:nil salt:nil completion:^(NSError *error) {
        completion(error);
    }];
}

-(void)saveToDocumentsDirectoryWithName:(NSString *)filename reducedFileSize:(BOOL)reducedFileSize password:(NSString *)password  salt:(NSString *)salt completion:(SaveFileBlock)completion{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    [self saveToUrl:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", paths[0], filename]] reducedFileSize:reducedFileSize password:password salt:salt completion:^(NSError *error) {
        completion(error);
    }];
}

-(void)saveToUrl:(NSURL *)url reducedFileSize:(BOOL)reducedSize password:(NSString *)password salt:(NSString *)salt completion:(SaveFileBlock)completion{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        //Get the JSON data
        NSMutableData *eData = [[self JSONDataWithReducedSize:reducedSize] mutableCopy];
        
        //Check for encryption. If desired, save the file encrypted.
        if (password) {
            if (password.length != 0) {
                if ([eData encryptWithKey:[eData generateAESKeyForPassword:password salt:salt]]) {
                    
                    //Save data
                    NSError *error = nil;
                    [eData writeToFile:url.path options:NSDataWritingAtomic error:&error];
                    
                    //Call back
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(error);
                    });
                    return;
                }
            }
        }
        
        //If no encryption, then save the file unencrypted.
         NSError *error = nil;
        [eData writeToFile:url.path options:NSDataWritingAtomic error:&error];
        
        //Call back
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(error);
        });
        return;
    });
}

#pragma mark - Load File

-(void)loadFromUrl:(NSURL *)url completion:(LoadFileBlock)completion{
    [self loadFromUrl:url password:nil salt:nil completion:^(id object, NSError *error) {
        completion(object, error);
    }];
}

-(void)loadFromUrl:(NSURL *)url password:(NSString *)password  salt:(NSString *)salt completion:(LoadFileBlock)completion{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError *error;
        
        NSMutableData *jsonData  = [[[NSData alloc] initWithContentsOfFile:url.path] mutableCopy];
        if (password.length > 0) {
            
            BOOL decryptWorked = [jsonData decryptWithKey:[jsonData generateAESKeyForPassword:password salt:salt]];
            if (!decryptWorked) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error = [NSError errorWithDomain:@"The specified file could not be decrypted." code:001 userInfo:nil];
                     completion(nil, error);
                });
                return;
            }
        }
        
        //Make json int dictionary
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
        
        //Check for error. Print e
        if (error) {
            
            NSLog(@"File reading error: %@", error.localizedDescription);
        }
        else {
            //Build object from json dictionary
            id object = [self objectFromDictionary:jsonDict];
            
            //Call Back
            dispatch_async(dispatch_get_main_queue(), ^{
                if (object) {
                    completion(object, nil);
                }
                else {
                    NSError *error = [NSError errorWithDomain:@"Could not create object from file. Object structure may not match document structure." code:002 userInfo:nil];
                    completion(object, error);
                }
            });
           
        }
        
    });
}

-(void)loadFromDocumentsDirectoryWithName:(NSString *)filename completion:(LoadFileBlock)completion{
    [self loadFromDocumentsDirectoryWithName:filename password:nil salt:nil completion:^(id object, NSError *error) {
        completion(object, error);
    }];
}

-(void)loadFromDocumentsDirectoryWithName:(NSString *)filename password:(NSString *)password salt:(NSString *)salt completion:(LoadFileBlock)completion{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    [self loadFromUrl:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", paths[0], filename]] password:password salt:salt completion:^(id object, NSError *error) {
        completion(object, error);
    }];
}

#pragma mark - Object from Dictionary
-(id)objectFromDictionary:(NSDictionary *)dict {
    if (dict.allKeys.count == 2 && dict[@"O"] && dict[@"M"]) {
        return [NSObject objectOfClass:[self nameOfClass] fromJSON:dict[@"O"] withMap:dict[@"M"] reducedSize:YES];
    }
    
    return [NSObject objectOfClass:[self nameOfClass] fromJSON:dict withMap:nil reducedSize:NO];
}




#pragma mark - Dictionary to Object
+(id)objectOfClass:(NSString *)object fromJSON:(NSDictionary *)dict withMap:(NSDictionary *)map reducedSize:(BOOL)reduced {
    id newObject = [[NSClassFromString(object) alloc] init];
    
    NSDictionary *mapDictionary = [newObject propertyDictionary];
    
    for (NSString *key in [dict allKeys]) {
        @autoreleasepool {
            NSString *propertyName = reduced ? [map objectForKey:[NSString stringWithFormat:@"%@:%@", object, key]] : [mapDictionary objectForKey:key];
            
            
            if (!propertyName) {
                continue;
            }
            
            // If it's a Dictionary, make into object
            if ([[dict objectForKey:key] isKindOfClass:[NSDictionary class]]) {
                NSString *propertyType = [newObject classOfPropertyNamed:propertyName];
                id nestedObj = [NSObject objectOfClass:propertyType fromJSON:[dict objectForKey:key] withMap:map reducedSize:reduced];
                [newObject setValue:nestedObj forKey:propertyName];
            }
            
            // If it's an array, check for each object in array -> make into object/id
            else if ([[dict objectForKey:key] isKindOfClass:[NSArray class]]) {
                NSArray *nestedArray = [dict objectForKey:key];
                NSString *propertyType = [newObject valueForKeyPath:[NSString stringWithFormat:@"propertyArrayMap.%@", (reduced ? propertyName : key)]];
                [newObject setValue:[NSObject arrayMapFromArray:nestedArray forPropertyName:propertyType withMap:map reducedSize:reduced] forKey:propertyName];
            }
            
            // Add to property name, because it is a type already
            else {
                objc_property_t property = class_getProperty([newObject class], [propertyName UTF8String]);
                NSString *classType = [newObject typeFromProperty:property];
                
                // check if NSDate or not
                if ([classType isEqualToString:@"NSDate"]) {
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:OMDateFormat];
                    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:OMTimeZone]];
                    NSString *dateString = [[dict objectForKey:key] stringByReplacingOccurrencesOfString:@"T" withString:@" "];
                    [newObject setValue:[formatter dateFromString:dateString] forKey:propertyName];
                }
                else {
                    if ([dict objectForKey:key] != [NSNull null]) {
                        [newObject setValue:[dict objectForKey:key] forKey:propertyName];
                    }
                    else {
                        [newObject setValue:nil forKey:propertyName];
                    }
                }
            }
        }
        
    }
    
    return newObject;
}

-(NSString *)classOfPropertyNamed:(NSString *)propName {
    unsigned count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    for (int xx = 0; xx < count; xx++) {
        @autoreleasepool {
            if ([[NSString stringWithUTF8String:property_getName(properties[xx])] isEqualToString:propName]) {
                NSString *className = [self typeFromProperty:properties[xx]];
                free(properties);
                return className;
            }
        }
    
    }
    
    return nil;
}

+(NSArray *)arrayFromJSON:(NSArray *)jsonArray ofObjects:(NSString *)obj withMap:(NSDictionary *)map reducedSize:(BOOL)reduced {
    return [NSObject arrayMapFromArray:jsonArray forPropertyName:obj withMap:map reducedSize:reduced];
}

-(NSString *)nameOfClass {
    return [NSString stringWithUTF8String:class_getName([self class])];
}

+(NSArray *)arrayMapFromArray:(NSArray *)nestedArray forPropertyName:(NSString *)propertyName withMap:(NSDictionary *)map reducedSize:(BOOL)reduced  {
    // Set Up
    NSMutableArray *objectsArray = [@[] mutableCopy];

    // Create objects
    for (int xx = 0; xx < nestedArray.count; xx++) {
        @autoreleasepool {
            // If it's an NSDictionary
            if ([nestedArray[xx] isKindOfClass:[NSDictionary class]]) {
                // Create object of filteredProperty type
                id nestedObj = [[NSClassFromString(propertyName) alloc] init];
                
                // Iterate through each key, create objects for each
                for (NSString *newKey in [nestedArray[xx] allKeys]) {
                    @autoreleasepool {
                        // If it's an Array, recur
                        if ([[nestedArray[xx] objectForKey:newKey] isKindOfClass:[NSArray class]]) {
                            NSString *propertyType = [nestedObj valueForKeyPath:[NSString stringWithFormat:@"propertyArrayMap.%@", (reduced ? [map objectForKey:[NSString stringWithFormat:@"%@:%@", propertyName, newKey]] : newKey)]];
                            [nestedObj setValue:[NSObject arrayMapFromArray:[nestedArray[xx] objectForKey:newKey] forPropertyName:propertyType withMap:map reducedSize:reduced] forKey:(reduced ? [map objectForKey:[NSString stringWithFormat:@"%@:%@", propertyName, newKey]] : newKey)];
                        }
                        // If it's a Dictionary, create an object, and send to [self objectFromJSON]
                        else if ([[nestedArray[xx] objectForKey:newKey] isKindOfClass:[NSDictionary class]]) {
                            NSString *type = [nestedObj classOfPropertyNamed:(reduced ? [map objectForKey:[NSString stringWithFormat:@"%@:%@", propertyName, newKey]] : newKey)];
                            
                            id nestedDictObj = [NSObject objectOfClass:type fromJSON:[nestedArray[xx] objectForKey:newKey] withMap:map reducedSize:reduced];
                            [nestedObj setValue:nestedDictObj forKey:(reduced ? [map objectForKey:[NSString stringWithFormat:@"%@:%@", propertyName, newKey]] : newKey)];
                        }
                        // Else, it is an object
                        else {
                            objc_property_t property = class_getProperty([NSClassFromString(propertyName) class], [(reduced ? [map objectForKey:[NSString stringWithFormat:@"%@:%@", propertyName, newKey]] : newKey) UTF8String]);
                            NSString *classType = [self typeFromProperty:property];
                            // check if NSDate or not
                            if ([classType isEqualToString:@"NSDate"]) {
                                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                [formatter setDateFormat:OMDateFormat];
                                [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:OMTimeZone]];
                                NSString *dateString = [[nestedArray[xx] objectForKey:newKey] stringByReplacingOccurrencesOfString:@"T" withString:@" "];
                                [nestedObj setValue:[formatter dateFromString:dateString] forKey:(reduced ? [map objectForKey:[NSString stringWithFormat:@"%@:%@", propertyName, newKey]] : newKey)];
                            }
                            else {
                                [nestedObj setValue:[nestedArray[xx] objectForKey:newKey] forKey:(reduced ? [map objectForKey:[NSString stringWithFormat:@"%@:%@", propertyName, newKey]] : newKey)];
                            }
                        }
                    }
                }
                
                // Finally add that object
                [objectsArray addObject:nestedObj];
            }
            
            // If it's an NSArray, recur
            else if ([nestedArray[xx] isKindOfClass:[NSArray class]]) {
                [objectsArray addObject:[NSObject arrayMapFromArray:nestedArray[xx] forPropertyName:propertyName withMap:map reducedSize:reduced]];
            }
            
            // Else, add object directly
            else {
                [objectsArray addObject:nestedArray[xx]];
            }
        }
        
    }
    
    // This is now an Array of objects
    return objectsArray;
}

-(NSDictionary *)propertyDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    unsigned count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    for (int i = 0; i < count; i++) {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        [dict setObject:key forKey:key];
    }
    
    free(properties);
    
    // Add all superclass properties as well, until it hits NSObject
    NSString *superClassName = [[self superclass] nameOfClass];
    if (![superClassName isEqualToString:@"NSObject"]) {
        for (NSString *property in [[[self superclass] propertyDictionary] allKeys]) {
            [dict setObject:property forKey:property];
        }
    }
    
    return dict;
}

-(NSString *)typeFromProperty:(objc_property_t)property {
    NSString *attrString = [self attributeStringFromProperty:property];
    NSArray *attrArray = [attrString componentsSeparatedByString:@"\""];
    return attrArray.count > 1 ? attrArray[1] : attrArray[0];
    //return [[NSString stringWithUTF8String:property_getAttributes(property)] componentsSeparatedByString:@","][0];
}

-(NSString *)attributeStringFromProperty:(objc_property_t)property {
    const char *attributes = property_getAttributes(property);
    return [NSString stringWithFormat:@"%s", attributes];
}

#pragma mark - Get Property Array Map
// This returns an associated property Dictionary for objects
// You should make an object contain a dictionary in init
// that contains a map for each array and what it contains:
//
// {"arrayPropertyName":"TypeOfObjectYouWantInArray"}
//
// To Set this object in each init method, do something like this:
//
// [myObject setValue:@"TypeOfObjectYouWantInArray" forKeyPath:@"propertyArrayMap.arrayPropertyName"]
//
-(NSMutableDictionary *)getPropertyArrayMap {
    if (objc_getAssociatedObject(self, @"propertyArrayMap")==nil) {
        objc_setAssociatedObject(self,@"propertyArrayMap",[[NSMutableDictionary alloc] init],OBJC_ASSOCIATION_RETAIN);
    }
    return (NSMutableDictionary *)objc_getAssociatedObject(self, @"propertyArrayMap");
}

#pragma mark - Object to Data/String/etc.

-(NSData *)JSONDataWithReducedSize:(BOOL)reducedSize{
    if (reducedSize) {
        NSDictionary *dict = [NSObject dictionaryWithPropertiesOfObject:self reducedSize:YES];
        NSMutableArray *dummyArray = [@[] mutableCopy];
        NSDictionary *mapDict = [NSObject dictionaryMapForObject:self inputarray:&dummyArray];
        return [NSJSONSerialization dataWithJSONObject:@{@"O":dict,@"M":mapDict} options:kNilOptions error:nil];
    }
    else {
        NSDictionary *dict = [NSObject dictionaryWithPropertiesOfObject:self reducedSize:NO];
        return [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
    }
}

-(NSString *)JSONString{
    NSDictionary *dict = [NSObject dictionaryWithPropertiesOfObject:self reducedSize:NO];
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
}

+(NSDictionary *)dictionaryWithPropertiesOfObject:(id)obj reducedSize:(BOOL)reducedSize
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    unsigned count;
    objc_property_t *properties = class_copyPropertyList([obj class], &count);
    
    for (int i = 0; i < count; i++) {
        @autoreleasepool {
            NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
            NSString *mapppedKey = key;
            if(reducedSize){
                mapppedKey = [NSString stringWithFormat:@"%c", (char)(48+i)];
            }
            
            if ([[obj valueForKey:key] isKindOfClass:[NSArray class]]) {
                [dict setObject:[self arrayForObject:[obj valueForKey:key] reducedSize:reducedSize] forKey:mapppedKey];
            }
            else if ([[obj valueForKey:key] isKindOfClass:[NSDate class]]){
                [dict setObject:[self dateForObject:[obj valueForKey:key]] forKey:mapppedKey];
            }
            else if ([self isSystemObject:obj key:key]) {
                [dict setObject:[obj valueForKey:key] forKey:mapppedKey];
            }
            else if ([[obj valueForKey:key] isKindOfClass:[NSData class]]){
                [dict setObject:[NSObject encodeBase64WithData:[obj valueForKey:key]] forKey:mapppedKey];
            }
            else {
                [dict setObject:[self dictionaryWithPropertiesOfObject:[obj valueForKey:key] reducedSize:reducedSize] forKey:mapppedKey];
            }
        }
        
    }
    
    free(properties);
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

-(BOOL)isSystemObject:(id)obj key:(NSString *)key{
    if ([[obj valueForKey:key] isKindOfClass:[NSString class]] || [[obj valueForKey:key] isKindOfClass:[NSNumber class]]) {
        return YES;
    }
    
    return NO;
}

-(BOOL)isSystemObject:(id)obj{
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]) {
        return YES;
    }
    
    return NO;
}

+(NSArray *)arrayForObject:(id)obj reducedSize:(BOOL)reducedSize{
    NSArray *ContentArray = (NSArray *)obj;
    NSMutableArray *objectsArray = [[NSMutableArray alloc] init];
    for (int ii = 0; ii < ContentArray.count; ii++) {
         @autoreleasepool {
             if ([ContentArray[ii] isKindOfClass:[NSArray class]]) {
                 [objectsArray addObject:[self arrayForObject:[ContentArray objectAtIndex:ii] reducedSize:reducedSize]];
             }
             else if ([ContentArray[ii] isKindOfClass:[NSDate class]]){
                 [objectsArray addObject:[self dateForObject:[ContentArray objectAtIndex:ii]]];
             }
             else if ([self isSystemObject:[ContentArray objectAtIndex:ii]]) {
                 [objectsArray addObject:[ContentArray objectAtIndex:ii]];
             }
             else {
                 [objectsArray addObject:[self dictionaryWithPropertiesOfObject:[ContentArray objectAtIndex:ii] reducedSize:reducedSize]];
             }
         }
    }
    
    return objectsArray;
}


+(NSString *)dateForObject:(id)obj{
    NSDate *date = (NSDate *)obj;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:OMDateFormat];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:OMTimeZone]];
    return [formatter stringFromDate:date];
}


+(NSDictionary *)dictionaryMapForObjects:(NSMutableArray *)objects{
    NSMutableDictionary *dict = [@{} mutableCopy];
    
    for (int ii = 0; ii < objects.count; ii++) {
        unsigned count;
        objc_property_t *properties = class_copyPropertyList([objects[ii] class], &count);
        
        for (int i = 0; i < count; i++) {
            NSString *mapString = [NSString stringWithFormat:@"%c", (char)(48+i)];
            [dict setValue:[NSString stringWithFormat:@"%s", property_getName(properties[i])] forKey:[NSString stringWithFormat:@"%@:%@",[objects[ii] nameOfClass],mapString]];
        }
    }
    
    return dict;
}

+(NSDictionary *) dictionaryMapForObject:(id)obj inputarray:(NSMutableArray **)inputarray
{
    if (![NSObject object:object_getClassName(obj) isInArray:inputarray]) {
        [(*inputarray) addObject:[[NSClassFromString([obj nameOfClass]) alloc] init]];
    }
    else {
        return nil;
    }
    
    unsigned count;
    objc_property_t *properties = class_copyPropertyList([obj class], &count);
    
    for (int i = 0; i < count; i++) {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        
        if ([[obj valueForKey:key] isKindOfClass:[NSArray class]]) {
            [NSObject mapArray:[obj valueForKey:key] inputarray:inputarray];
        }
        else if(![[obj valueForKey:key] isKindOfClass:[NSString class]] && ![[obj valueForKey:key] isKindOfClass:[NSData class]] && ![[obj valueForKey:key] isKindOfClass:[NSDate class]] && ![[obj valueForKey:key] isKindOfClass:[NSNumber class]]){
            [self dictionaryMapForObject:[obj valueForKey:key] inputarray:inputarray];
        }
    }
    
    free(properties);
    
    return [self dictionaryMapForObjects:*inputarray];
}

+(void)mapArray:(id)obj inputarray:(NSMutableArray **)inputarray{
    NSArray *ContentArray = (NSArray *)obj;
    
    for (int ii = 0; ii < ContentArray.count; ii++) {
        if ([ContentArray[ii] isKindOfClass:[NSArray class]]) {
            [self mapArray:[ContentArray objectAtIndex:ii] inputarray:inputarray];
        }
        else {
            [NSObject dictionaryMapForObject:[ContentArray objectAtIndex:ii] inputarray:inputarray];
        }
        
    }
}

+(BOOL)object:(const char *)object isInArray:(NSMutableArray **)inputArray{
    
    for (id arrayObject in (*inputArray)) {
        if (object_getClassName(arrayObject) == object) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Base64 Binary Encode/Decode

+(NSData *)base64DataFromString:(NSString *)string
{
    unsigned long ixtext, lentext;
    unsigned char ch, inbuf[4], outbuf[3];
    short i, ixinbuf;
    Boolean flignore, flendtext = false;
    const unsigned char *tempcstring;
    NSMutableData *theData;
    
    if (string == nil)
    {
        return [NSData data];
    }
    
    ixtext = 0;
    
    tempcstring = (const unsigned char *)[string UTF8String];
    
    lentext = [string length];
    
    theData = [NSMutableData dataWithCapacity: lentext];
    
    ixinbuf = 0;
    
    while (true)
    {
        if (ixtext >= lentext)
        {
            break;
        }
        
        ch = tempcstring [ixtext++];
        
        flignore = false;
        
        if ((ch >= 'A') && (ch <= 'Z'))
        {
            ch = ch - 'A';
        }
        else if ((ch >= 'a') && (ch <= 'z'))
        {
            ch = ch - 'a' + 26;
        }
        else if ((ch >= '0') && (ch <= '9'))
        {
            ch = ch - '0' + 52;
        }
        else if (ch == '+')
        {
            ch = 62;
        }
        else if (ch == '=')
        {
            flendtext = true;
        }
        else if (ch == '/')
        {
            ch = 63;
        }
        else
        {
            flignore = true;
        }
        
        if (!flignore)
        {
            short ctcharsinbuf = 3;
            Boolean flbreak = false;
            
            if (flendtext)
            {
                if (ixinbuf == 0)
                {
                    break;
                }
                
                if ((ixinbuf == 1) || (ixinbuf == 2))
                {
                    ctcharsinbuf = 1;
                }
                else
                {
                    ctcharsinbuf = 2;
                }
                
                ixinbuf = 3;
                
                flbreak = true;
            }
            
            inbuf [ixinbuf++] = ch;
            
            if (ixinbuf == 4)
            {
                ixinbuf = 0;
                
                outbuf[0] = (inbuf[0] << 2) | ((inbuf[1] & 0x30) >> 4);
                outbuf[1] = ((inbuf[1] & 0x0F) << 4) | ((inbuf[2] & 0x3C) >> 2);
                outbuf[2] = ((inbuf[2] & 0x03) << 6) | (inbuf[3] & 0x3F);
                
                for (i = 0; i < ctcharsinbuf; i++)
                {
                    [theData appendBytes: &outbuf[i] length: 1];
                }
            }
            
            if (flbreak)
            {
                break;
            }
        }
    }
    
    return theData;
}

+ (NSString *)encodeBase64WithData:(NSData *)objData {
    const unsigned char * objRawData = [objData bytes];
    char * objPointer;
    char * strResult;
    
    // Get the Raw Data length and ensure we actually have data
    int intLength = [objData length];
    if (intLength == 0) return nil;
    
    // Setup the String-based Result placeholder and pointer within that placeholder
    strResult = (char *)calloc(((intLength + 2) / 3) * 4, sizeof(char));
    objPointer = strResult;
    
    // Iterate through everything
    while (intLength > 2) { // keep going until we have less than 24 bits
        *objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
        *objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
        *objPointer++ = _base64EncodingTable[((objRawData[1] & 0x0f) << 2) + (objRawData[2] >> 6)];
        *objPointer++ = _base64EncodingTable[objRawData[2] & 0x3f];
        
        // we just handled 3 octets (24 bits) of data
        objRawData += 3;
        intLength -= 3;
    }
    
    // now deal with the tail end of things
    if (intLength != 0) {
        *objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
        if (intLength > 1) {
            *objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
            *objPointer++ = _base64EncodingTable[(objRawData[1] & 0x0f) << 2];
            *objPointer++ = '=';
        } else {
            *objPointer++ = _base64EncodingTable[(objRawData[0] & 0x03) << 4];
            *objPointer++ = '=';
            *objPointer++ = '=';
        }
    }
    
    // Terminate the string-based result
    *objPointer = '\0';
    
    // Return the results as an NSString object
    return [NSString stringWithCString:strResult encoding:NSUTF8StringEncoding];
}

+(NSString *)generateSalt{
    NSMutableData *data = [NSMutableData dataWithLength:32];
    
    int result = SecRandomCopyBytes(kSecRandomDefault,
                                    32,
                                    data.mutableBytes);
    NSAssert(result == 0, @"Unable to generate random bytes: %d",
             errno);
    
    NSString *string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    return string;
}

-(NSString *)generateAESKeyForPassword:(NSString *)password salt:(NSString *)salt{
    //Add the salt to the key
    NSString *saltedKey = password;
    if (salt) {
        //Create hash of salt so it will be of appropriate length
        saltedKey = [password stringByAppendingString:salt];
    }
    
    NSMutableData *saltData = [NSMutableData dataWithData:[salt dataUsingEncoding:NSUTF8StringEncoding]];
    NSMutableData * derivedKey = [NSMutableData dataWithLength:kCCKeySizeAES128];
    
    int
    result = CCKeyDerivationPBKDF(kCCPBKDF2,            // algorithm
                                  password.UTF8String,  // password
                                  password.length,  // passwordLength
                                  saltData.bytes,           // salt
                                  saltData.length,          // saltLen
                                  kCCPRFHmacAlgSHA1,    // PRF
                                  kPBKDFRounds,         // rounds
                                  derivedKey.mutableBytes, // derivedKey
                                  derivedKey.length); // derivedKeyLen
    
    // Do not log password here
    NSAssert(result == kCCSuccess,
             @"Unable to create AES key for password: %d", result);
    
    unsigned char* bytes = (unsigned char *)derivedKey.bytes;
    
    NSString *AESKey = [NSString stringWithFormat:
                        @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                        bytes[0], bytes[1], bytes[2], bytes[3],
                        bytes[4], bytes[5], bytes[6], bytes[7],
                        bytes[8], bytes[9], bytes[10], bytes[11],
                        bytes[12], bytes[13], bytes[14], bytes[15]
                        ];
    
    return AESKey;
}

- (BOOL)encryptWithKey:(NSString *)key {
    return [self doCipher:key operation:kCCEncrypt];
}

- (BOOL)decryptWithKey:(NSString *)key {
    return [self doCipher:key operation:kCCDecrypt];
}

-(BOOL)doCipher:(NSString *)key operation:(CCOperation)operation
{
    
    if (![self isKindOfClass:[NSMutableData class]]) {
        return NO;
    }
    
    // The key should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256 + 1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr));     // fill with zeroes (for padding)
    
    // Fetch key data
    if (![key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding]) {return FALSE;} // Length of 'key' is bigger than keyPtr
    
    CCCryptorRef cryptor;
    CCCryptorStatus cryptStatus = CCCryptorCreate(operation, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                                  keyPtr, kCCKeySizeAES256,
                                                  NULL, // IV - needed?
                                                  &cryptor);
    
    if (cryptStatus != kCCSuccess) { // Handle error here
        return FALSE;
    }
    
    size_t dataOutMoved;
    size_t dataInLength = kChunkSizeBytes; // #define kChunkSizeBytes (16)
    size_t dataOutLength = CCCryptorGetOutputLength(cryptor, dataInLength, FALSE);
    size_t totalLength = 0; // Keeps track of the total length of the output buffer
    size_t filePtr = 0;   // Maintains the file pointer for the output buffer
    NSInteger startByte; // Maintains the file pointer for the input buffer
    
    char *dataIn = malloc(dataInLength);
    char *dataOut = malloc(dataOutLength);
    for (startByte = 0; startByte <= [(NSMutableData *)self length]; startByte += kChunkSizeBytes) {
        if ((startByte + kChunkSizeBytes) > [(NSMutableData *)self length]) {
            dataInLength = [(NSMutableData *)self length] - startByte;
        }
        else {
            dataInLength = kChunkSizeBytes;
        }
        
        // Get the chunk to be ciphered from the input buffer
        NSRange bytesRange = NSMakeRange((NSUInteger) startByte, (NSUInteger) dataInLength);
        [(NSMutableData *)self getBytes:dataIn range:bytesRange];
        cryptStatus = CCCryptorUpdate(cryptor, dataIn, dataInLength, dataOut, dataOutLength, &dataOutMoved);
        
        if (dataOutMoved != dataOutLength) {
            //NSLog(@"dataOutMoved (%zd) != dataOutLength (%zd)", dataOutMoved, dataOutLength);
        }
        
        if ( cryptStatus != kCCSuccess)
        {
            NSLog(@"Failed CCCryptorUpdate: %d", cryptStatus);
        }
        
        // Write the ciphered buffer into the output buffer
        bytesRange = NSMakeRange(filePtr, (NSUInteger) dataOutMoved);
        [(NSMutableData *)self replaceBytesInRange:bytesRange withBytes:dataOut];
        totalLength += dataOutMoved;
        
        filePtr += dataOutMoved;
    }
    
    // Finalize encryption/decryption.
    cryptStatus = CCCryptorFinal(cryptor, dataOut, dataOutLength, &dataOutMoved);
    totalLength += dataOutMoved;
    
    if ( cryptStatus != kCCSuccess)
    {
        NSLog(@"Failed CCCryptorFinal: %d", cryptStatus);
    }
    
    // In the case of encryption, expand the buffer if it required some padding (an encrypted buffer will always be a multiple of 16).
    // In the case of decryption, truncate our buffer in case the encrypted buffer contained some padding
    [(NSMutableData *)self setLength:totalLength];
    
    // Finalize the buffer with data from the CCCryptorFinal call
    NSRange bytesRange = NSMakeRange(filePtr, (NSUInteger) dataOutMoved);
    [(NSMutableData *)self replaceBytesInRange:bytesRange withBytes:dataOut];
    
    CCCryptorRelease(cryptor);
    
    free(dataIn);
    free(dataOut);
    
    return YES;
}



@end



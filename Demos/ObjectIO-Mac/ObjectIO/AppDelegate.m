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

#import "AppDelegate.h"
#import "NSObject+ObjectIO.h"
#import "SpaceObjects.h"

//#Error Please put your username here for saving documents to custom directories
#define USERNAME @"my3681"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //Create a test object structure (Something to save!)
    //Defaults to 8 planets, ~8 moons, and 1 million asteroids
    SolarSystem *testSolarSystem = [SolarSystem ourSolarSystem];
    
    //Test save and load with encryption and reduced file size
    //Saves to your documents folder
    [self saveAndLoadEncryptedSolarSystem:testSolarSystem];
    
    //Test save and load without encryption or reduced file size
    //Saves to your desktop
    [self saveAndLoadSolarSystem:testSolarSystem];
}

-(void)saveAndLoadEncryptedSolarSystem:(SolarSystem *)exampleSolarSystem{
    //Generate Salt
    //You will want to save this somewhere as it is necessary for decrypting the file
    NSString *salt = [NSMutableData generateSalt];
    
    NSString *fileName = @"ObjectIOTestReducedEncrypted.txt";
    
    //Save document
    [self.EncryptedStatusLabel setStringValue:@"Saving..."];
    [exampleSolarSystem saveToDocumentsDirectoryWithName:fileName reducedFileSize:YES password:@"Password1" salt:salt completion:^(NSError *error) {
        
        //Create a new solar system
        __block SolarSystem *encryptedSSReduced = [[SolarSystem alloc] init];
        
        //Load back the Solar System
        [self.EncryptedStatusLabel setStringValue:@"Loading..."];
        [encryptedSSReduced loadFromDocumentsDirectoryWithName:fileName password:@"Password1" salt:salt completion:^(id object, NSError *error) {
            
            //Assign object
            encryptedSSReduced = (SolarSystem *)object;
            
            //Get documents folder path
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            
             NSString *completionString = [NSString stringWithFormat:@"Complete - %@", [self fileSizeForPath:[NSString stringWithFormat:@"%@/%@", paths[0], fileName]]];
            
            //Give feedback
            NSLog(@"Encrypted and Reduced Save/Load Complete");
            [self.EncryptedStatusLabel setStringValue:completionString];
        }];
    }];
}

-(void)saveAndLoadSolarSystem:(SolarSystem *)exampleSolarSystem{
    //Save document
    [self.UnencryptedStatusLabel setStringValue:@"Saving..."];
    [exampleSolarSystem saveToUrl:[NSURL URLWithString:[NSString stringWithFormat:@"/Users/%@/Desktop/ObjectIOTestUnencrypted.txt", USERNAME]] completion:^(NSError *error) {
        
        //Check for an error (a little example of error handling)
        if (!error) {
            
            //If no error, create a sample Solar System
            __block SolarSystem *unencryptedSSReduced = [[SolarSystem alloc] init];
            
            //Load back the Solar System
            [self.UnencryptedStatusLabel setStringValue:@"Loading..."];
            
            //Get file path
            NSString *filePath = [NSString stringWithFormat:@"/Users/%@/Desktop/ObjectIOTestUnencrypted.txt", USERNAME];
            
            //Load object
            [unencryptedSSReduced loadFromUrl:[NSURL URLWithString:filePath] completion:^(id object, NSError *error) {
                
                //Assign object
                unencryptedSSReduced = (SolarSystem *)object;
                
                //Give feedback
                NSLog(@"Unencrypted Sav/Load Complete");
                
                NSString *completionString = [NSString stringWithFormat:@"Complete - %@", [self fileSizeForPath:filePath]];
                
                [self.UnencryptedStatusLabel setStringValue:completionString];
            }];
        }
        else {
            [self.UnencryptedStatusLabel setStringValue:@"Failed"];
            NSLog(@"Save Failed: %@", error);
        }
        
    }];
}

-(NSString *)fileSizeForPath:(NSString *)path{
    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
    
    if (fileSize < 1000) {
        return [NSString stringWithFormat:@"%lld bytes", fileSize];
    }
    else if (fileSize >= 1000 && fileSize < 1000000) {
        return [NSString stringWithFormat:@"%.2f kB", (float)fileSize/1000000];
    }
    else if (fileSize > 1000000) {
        return [NSString stringWithFormat:@"%.2f MB", (float)fileSize/1000000];
    }
    
    return @"";
}

@end
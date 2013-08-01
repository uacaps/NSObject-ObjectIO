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
#import "SolarSystem.h"

#define ASTEROID_COUNT 1000000
#define MAX_NUMBER_OF_MOONS 8

@implementation SolarSystem

-(id)init {
    self = [super init];
    if (self) {
        [self setValue:@"Star" forKeyPath:@"propertyArrayMap.Stars"];
        [self setValue:@"Planet" forKeyPath:@"propertyArrayMap.Planets"];
        [self setValue:@"Asteroid" forKeyPath:@"propertyArrayMap.Asteroids"];
    }
    
    return self;
}

+(SolarSystem *)ourSolarSystem {
    SolarSystem *ss = [[SolarSystem alloc] init];
    
    // Planets
    NSMutableArray *planets = [NSMutableArray array];
    NSArray *planetNames = @[@"Mercury", @"Venus", @"Earth", @"Mars", @"Jupiter", @"Saturn", @"Uranus", @"Neptune"];
    for (NSString *planet in planetNames) {
        Planet *newPlanet = [[Planet alloc] init];
        newPlanet.Name = planet;
        newPlanet.Size = @(arc4random() % 500000);
        
        NSMutableArray *moons = [NSMutableArray array];
        for (int x = 0; x < (arc4random() % MAX_NUMBER_OF_MOONS); x++) {
            Moon *newMoon = [[Moon alloc] init];
            newMoon.Name = [NSString stringWithFormat:@"%@%d", [planet substringToIndex:1], x];
            newMoon.Size = @(arc4random() % 30000);
            [moons addObject:newMoon];
        }
        newPlanet.Moons = moons;
        
        [planets addObject:newPlanet];
    }
    ss.Planets = planets;
    
    // Star
    Star *newStar = [[Star alloc] init];
    newStar.Name = @"Helios";
    newStar.Size = @(1391000);
    ss.Stars = @[newStar];
    
    // Asteroids
    NSMutableArray *asteroids = [NSMutableArray array];
    for (int ii = 0; ii < (ASTEROID_COUNT); ii++) {
        Asteroid *newA = [[Asteroid alloc] init];
        newA.Size = @(arc4random() % 6000);
        [asteroids addObject:newA];
    }
    ss.Asteroids = asteroids;
    
    return ss;
}

@end

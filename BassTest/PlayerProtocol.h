//
//  PlayerProtocol.h
//  BassTest
//
//  Created by Edson Teco on 23/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "bass.h"

@protocol PlayerProtocol <NSObject>

- (HSTREAM)channel;
- (NSString*)mp3;

@end

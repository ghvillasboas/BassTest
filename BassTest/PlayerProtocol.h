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

@optional

- (void)playerIsReady:(id<PlayerProtocol>)player;

- (void)playerWillPlay:(id<PlayerProtocol>)player;
- (void)playerDidPlay:(id<PlayerProtocol>)player;

- (void)playerWillPause:(id<PlayerProtocol>)player;
- (void)playerDidPause:(id<PlayerProtocol>)player;

- (void)playerWillStop:(id<PlayerProtocol>)player;
- (void)playerDidStop:(id<PlayerProtocol>)player;

@required

- (void)play:(id<PlayerProtocol>)player;
- (void)pause:(id<PlayerProtocol>)player;
- (void)stop:(id<PlayerProtocol>)player;

@property (nonatomic, readonly) HSTREAM channel;
@property (nonatomic, strong) NSString* pathToAudio;
@property (nonatomic, readonly) float bpm;
@property (nonatomic, readonly) BOOL isPlaying;

@end

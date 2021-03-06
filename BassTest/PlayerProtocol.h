//
//  PlayerProtocol.h
//  BassTest
//
//  Created by Edson Teco on 23/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "bass.h"

@protocol PlayerDataSource <NSObject>

@required

- (HSTREAM)channel;
- (NSString*)pathToAudio;
- (void)setPathToAudio:(NSString*)pathToAudio;
- (BOOL)isPlaying;

@optional

- (float)bpm;
- (void)setChannel:(HSTREAM)channel;

@end

@protocol PlayerDelegate <NSObject>

@optional

- (void)playerIsReady:(id<PlayerDataSource>)player;

- (void)playerWillPlay:(id<PlayerDataSource>)player;
- (void)playerDidPlay:(id<PlayerDataSource>)player;

- (void)playerWillPause:(id<PlayerDataSource>)player;
- (void)playerDidPause:(id<PlayerDataSource>)player;

- (void)playerWillStop:(id<PlayerDataSource>)player;
- (void)playerDidStop:(id<PlayerDataSource>)player;

- (void)play:(id<PlayerDataSource>)player;
- (void)pause:(id<PlayerDataSource>)player;
- (void)stop:(id<PlayerDataSource>)player;

@end
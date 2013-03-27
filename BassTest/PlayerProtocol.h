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

@optional

- (HSTREAM)channel;
- (void)setPathToAudio:(NSString*)pathToAudio;
- (float)bpm;
- (BOOL)isPlaying;

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

@required

- (void)play:(id<PlayerDataSource>)player;
- (void)pause:(id<PlayerDataSource>)player;
- (void)stop:(id<PlayerDataSource>)player;

@end
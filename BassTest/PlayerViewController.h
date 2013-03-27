//
//  PlayerViewController.h
//  BassTest
//
//  Created by George Henrique Villasboas on 22/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrataErros.h"
#import "bass.h"
#import "bassenc.h"
#import "bassmix.h"
#import "PlayerProtocol.h"

@class PlayerViewController;

@interface PlayerViewController : UIViewController <PlayerDataSource, PlayerDelegate>

@property (nonatomic, strong) TrataErros *trataErros;
@property (weak, nonatomic) UITextView *loggerInfo;
@property (weak, nonatomic) IBOutlet UITextView *loggerTime;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;

@property (nonatomic, weak) id<PlayerDelegate> delegate;

@property (nonatomic) HSTREAM channel;
@property (nonatomic, strong) NSString* pathToAudio;
@property (nonatomic, readonly) float bpm;
@property (nonatomic, readonly) BOOL isPlaying;

@end

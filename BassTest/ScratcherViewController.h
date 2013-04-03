//
//  AudioScratchDemoViewController.h
//  AudioScratchDemo
//
//  Created by Jan Kalis on 10/22/10.
//  Copyright 2010 Glow Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <MediaPlayer/MediaPlayer.h>
#import "bass.h"
#import "bass_fx.h"
#import "Scratcher.h"
#import "PlayerProtocol.h"

@interface ScratcherViewController : UIViewController <PlayerDelegate, PlayerDataSource, MPMediaPickerControllerDelegate>

@property (strong, nonatomic) IBOutlet UIImageView* vinyl;
@property (strong, nonatomic) IBOutlet UIImageView* imgBrilho;
@property (strong, nonatomic) IBOutlet UIImageView* imgDeck;
@property (strong, nonatomic) IBOutlet UIImageView* imgDisco;
@property (nonatomic) BOOL animating;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet UIButton *PlayButton;
@property (weak, nonatomic) IBOutlet UIButton *StopButton;
@property (weak, nonatomic) IBOutlet UITextView *loggerTime;

@property (nonatomic, weak) id<PlayerDelegate> delegate;

@property (nonatomic, readonly) HSTREAM channel;
@property (nonatomic, strong) NSString* pathToAudio;
@property (nonatomic, strong) NSString* pathToAudioStop;
@property (nonatomic, readonly) float bpm;
@property (nonatomic, readonly) BOOL isLoaded;
@property (nonatomic, readonly) BOOL isPlaying;

@end


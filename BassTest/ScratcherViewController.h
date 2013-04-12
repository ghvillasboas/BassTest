//
//  AudioScratchDemoViewController.h
//  AudioScratchDemo
//
//  Created by Jan Kalis on 10/22/10.
//  Copyright 2010 Glow Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreMedia/CoreMedia.h>

#import "bass.h"
#import "bass_fx.h"
#import "Scratcher.h"
#import "PlayerProtocol.h"

@interface ScratcherViewController : UIViewController <PlayerDelegate, PlayerDataSource>

@property (strong, nonatomic) IBOutlet UIImageView* imgBrilho;
@property (strong, nonatomic) IBOutlet UIImageView* imgDeck;
@property (strong, nonatomic) IBOutlet UIView* imgDisco;
@property (strong, nonatomic) IBOutlet UIImageView* imgRotulo;
@property (strong, nonatomic) IBOutlet UIImageView* imgLaser;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* loadingSpin;
@property (nonatomic) BOOL animating;

@property (nonatomic, weak) id<PlayerDelegate> delegate;

@property (nonatomic, readonly) HSTREAM channel;
@property (nonatomic, strong) NSString* pathToAudio;
@property (nonatomic, strong) NSString* pathToAudioStop;
@property (nonatomic, readonly) float bpm;
@property (nonatomic) BOOL isLoaded;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) BOOL isOn;
@property (nonatomic) float volume;
@property (nonatomic) int identificador;
@property (nonatomic, strong) UIImage *artWork;
@property (nonatomic) int progress;

- (void)stop;
- (void)free;
- (UIImage *)maskImage:(UIImage *)image withMask:(UIImage *)maskImage;
- (id)initWithFrame:(CGRect)frame;

@end


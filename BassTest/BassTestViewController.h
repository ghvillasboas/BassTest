//
//  BassTestViewController.h
//  BassTest
//
//  Created by George Henrique Villasboas on 21/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "Mixer.h"
#import "PlayerViewController.h"
#import "ScratcherViewController.h"
#import "PlayerProtocol.h"

@interface BassTestViewController : UIViewController <PlayerDelegate, MPMediaPickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *holderPlayer1;

@property (weak, nonatomic) IBOutlet UIButton *recGeralButton;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (weak, nonatomic) IBOutlet UIButton *powerButton;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@property (strong, nonatomic) ScratcherViewController *scratcherViewController;

@property (strong, nonatomic) Mixer *mixer;
@property (strong, nonatomic) NSTimer *updateProgress;

@end

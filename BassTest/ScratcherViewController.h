//
//  AudioScratchDemoViewController.h
//  AudioScratchDemo
//
//  Created by Jan Kalis on 10/22/10.
//  Copyright 2010 Glow Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "bass.h"
#import "Scratcher.h"

@class ScratcherViewController;

@protocol ScratcherDelegate <NSObject>

- (void)tocarScratcher:(ScratcherViewController*)requestor;
- (void)pausarScratcher:(ScratcherViewController *)requestor;
- (void)pararScratcher:(ScratcherViewController*)requestor;

@end

@interface ScratcherViewController : UIViewController 

@property (strong, nonatomic) IBOutlet UIImageView* vinyl;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet UIButton *PlayButton;
@property (weak, nonatomic) IBOutlet UIButton *StopButton;

@property (strong, nonatomic) NSString *mp3;
@property (readonly, nonatomic) HSTREAM channel;
@property (nonatomic) BOOL tocando;
@property (nonatomic, weak) id<ScratcherDelegate> delegate;



@end


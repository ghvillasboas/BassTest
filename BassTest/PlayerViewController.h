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

@class PlayerViewController;

@protocol PlayerDelegate <NSObject>

- (void)tocar:(PlayerViewController*)requestor;
- (void)pausar:(PlayerViewController *)requestor;
- (void)parar:(PlayerViewController*)requestor;

@end

@interface PlayerViewController : UIViewController
@property HSTREAM channel;
@property (nonatomic, strong) NSString *mp3;
@property (nonatomic) BOOL tocando;
@property (nonatomic, strong) TrataErros *trataErros;
@property (weak, nonatomic) IBOutlet UITextView *loggerTime;
@property (weak, nonatomic) IBOutlet UITextView *loggerInfo;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *recButton;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;

@property (nonatomic, weak) id<PlayerDelegate> delegate;

@end

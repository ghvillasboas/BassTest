//
//  BassTestViewController.h
//  BassTest
//
//  Created by George Henrique Villasboas on 21/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Mixer.h"
#import "PlayerViewController.h"
#import "bassenc.h"


@interface BassTestViewController : UIViewController <PlayerDelegate>

@property (weak, nonatomic) IBOutlet UIView *holderPlayer1;
@property (weak, nonatomic) IBOutlet UIView *holderPlayer2;
@property (strong, nonatomic) PlayerViewController *player1;
@property (strong, nonatomic) PlayerViewController *player2;
@property (weak, nonatomic) IBOutlet UIButton *recGeralButton;

@property (strong, nonatomic) Mixer *mixer;

@end

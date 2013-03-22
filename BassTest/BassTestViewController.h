//
//  BassTestViewController.h
//  BassTest
//
//  Created by George Henrique Villasboas on 21/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "bass.h"
#import "bassenc.h"
#import "bassmix.h"
#import "PlayerViewController.h"

@interface BassTestViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *holderPlayer1;
@property (weak, nonatomic) IBOutlet UIView *holderPlayer2;
@property (strong, nonatomic) PlayerViewController *player1;
@property (strong, nonatomic) PlayerViewController *player2;
@property (weak, nonatomic) IBOutlet UIButton *recGeralButton;

@property HSTREAM streamGeral;
@property HENCODE encode;


@end

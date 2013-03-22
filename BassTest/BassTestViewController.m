//
//  BassTestViewController.m
//  BassTest
//
//  Created by George Henrique Villasboas on 21/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import "BassTestViewController.h"

@interface BassTestViewController ()

@end

@implementation BassTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.player1 = [[PlayerViewController alloc] init];
    self.player2 = [[PlayerViewController alloc] init];
    
    self.player1.mp3 = [[NSBundle mainBundle] pathForResource:@"audio1" ofType:@"mp3"];
    self.player2.mp3 = [[NSBundle mainBundle] pathForResource:@"audio2" ofType:@"mp3"];

    [self addChildViewController:self.player1];
    [self.holderPlayer1 addSubview:self.player1.view];
    [self.player1 didMoveToParentViewController:self];
    
    [self addChildViewController:self.player2];
    [self.holderPlayer2 addSubview:self.player2.view];
    [self.player2 didMoveToParentViewController:self];
}
@end

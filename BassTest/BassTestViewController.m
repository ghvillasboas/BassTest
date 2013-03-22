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

- (IBAction)recGeral:(id)sender
{
    NSLog(@"Gravando geral...");
    
    // Efetua o link dos canais...
    BASS_ChannelSetLink(self.player1.channel, self.player2.channel);
    
    if (BASS_Encode_IsActive(self.encode) == BASS_ACTIVE_PLAYING) {
        BASS_Encode_Stop(self.encode);
        BASS_ChannelStop(self.player1.channel);
    }
    else {
        
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *file = [documentsDirectory stringByAppendingPathComponent:@"tudoJunto.m4a"];
        NSLog(@"%@", file);
        self.encode = BASS_Encode_StartCAFile(self.player1.channel, 'm4af', 'alac', BASS_ENCODE_FP_16BIT, 0, [file cStringUsingEncoding:NSUTF8StringEncoding]);
        if (self.encode == 0) {
            NSLog(@"%@", @"Erro");
        }
        else {
            BASS_ChannelPlay(self.player1.channel, 0);
        }
    }
}

@end

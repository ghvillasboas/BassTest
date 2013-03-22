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
    
    if (BASS_Encode_IsActive(self.encode) == BASS_ACTIVE_PLAYING) {
        BASS_Encode_Stop(self.encode);
        BASS_ChannelStop(self.streamGeral);
        NSLog(@"%@", @"Gravação encerrada");
    }
    else {
        // Arquivo de saída
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *file = [documentsDirectory stringByAppendingPathComponent:@"output.m4a"];

        // Cria o Stream Geral
        self.streamGeral = BASS_Mixer_StreamCreate(44100, 2, BASS_SAMPLE_SOFTWARE|BASS_STREAM_AUTOFREE);
        
        // mixa os canais
//        if (self.player1.tocando) {
            BASS_Mixer_StreamAddChannel(self.streamGeral, self.player1.channel, BASS_STREAM_AUTOFREE);
//        }
//        if (self.player2.tocando) {
            BASS_Mixer_StreamAddChannel(self.streamGeral, self.player2.channel, BASS_STREAM_AUTOFREE);
//        }
        
        // inicia a gravação
        self.encode = BASS_Encode_StartCAFile(self.streamGeral, 'm4af', 'alac', BASS_ENCODE_FP_16BIT, 0, [file cStringUsingEncoding:NSUTF8StringEncoding]);
        if (self.encode == 0) {
            NSLog(@"%@", @"Erro ao criar o encode");
        }
        else {
            if (BASS_ChannelPlay(self.streamGeral, 0)) {
                NSLog(@"%@ %@", @"Gravação iniciada em", file);
            }
            else {
                NSLog(@"%@", @"Erro: Gravação não iniciada!");
            }
        }
    }
}

@end

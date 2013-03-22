//
//  BassTestViewController.m
//  BassTest
//
//  Created by George Henrique Villasboas on 21/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import "BassTestViewController.h"
#import "bass.h"
#import "bassenc.h"

@interface BassTestViewController ()

@property HSTREAM channel;
@property HENCODE encode;
@property (weak, nonatomic) IBOutlet UITextView *logger;
@property (weak, nonatomic) IBOutlet UITextView *logger2;
@property (strong, nonatomic) NSTimer *loggerUpdaterTimer;

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

- (void)updateTimer:(NSTimer *)timer
{
    QWORD pos=BASS_ChannelGetPosition(self.channel, BASS_POS_BYTE);
    int time=BASS_ChannelBytes2Seconds(self.channel, pos);
    self.logger2.text = [NSString stringWithFormat:@"Lido: %llu bytes\nTempo total: %u:%02u", pos, time/60, time%60];
}

- (IBAction)play:(id)sender
{
    // Importante o segundo argumento. Se FALSE e o usuario parar o stream e tocar em play novamente,
    // o stream continua de onde parou, funcionando como um pause. Se TRUE, o comportamento e o esperado.
    // Ou seja, se o usuario parar o stream e tocar em play, ele reinicia.
    BASS_ChannelPlay(self.channel, TRUE);
    
    [self updateLog];
}

- (IBAction)stop:(id)sender
{
    BASS_ChannelStop(self.channel);
    
    [self clearLog];
}

- (IBAction)record:(id)sender
{
    if (BASS_Encode_IsActive(self.encode) == BASS_ACTIVE_PLAYING) {
        BASS_Encode_Stop(self.encode);
        BASS_ChannelStop(self.channel);
    }
    else {
        
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *file = [documentsDirectory stringByAppendingPathComponent:@"output.m4a"];
        NSLog(@"%@", file);
        self.encode = BASS_Encode_StartCAFile(self.channel, 'm4af', 'alac', BASS_ENCODE_FP_16BIT, 0, [file cStringUsingEncoding:NSUTF8StringEncoding]);
        if (self.encode == 0) {
            NSLog(@"%@", @"Erro");
        }
        else {
            BASS_ChannelPlay(self.channel, 0);
            [self updateLog];
        }
    }
}
@end

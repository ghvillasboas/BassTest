//
//  BassTestViewController.m
//  BassTest
//
//  Created by George Henrique Villasboas on 21/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import "BassTestViewController.h"
#import "bass.h"

@interface BassTestViewController ()
@property HSTREAM channel;
@property (weak, nonatomic) IBOutlet UITextView *logger;
@property (weak, nonatomic) IBOutlet UITextView *logger2;
@property (strong, nonatomic) NSTimer *loggerUpdaterTimer;
@end

@implementation BassTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
	if (!BASS_Init(-1,44100,0,0,NULL))
        NSLog(@"Não foi possivel inicializar o BASS");
    
    
    NSString *file = [[NSBundle mainBundle] pathForResource:@"audio1" ofType:@"mp3"];
    self.channel = BASS_StreamCreateFile(FALSE, [file cStringUsingEncoding:NSUTF8StringEncoding], 0, 0, BASS_SAMPLE_LOOP);
    
}

- (void)updateLog
{
    TAG_ID3 *id3 = (TAG_ID3*)BASS_ChannelGetTags(self.channel, BASS_TAG_ID3);
    QWORD pos = BASS_ChannelGetLength(self.channel, BASS_POS_BYTE);
    int time = BASS_ChannelBytes2Seconds(self.channel, pos);
    NSString *log = [NSString stringWithFormat:@"TAGs ID3\nMusica: %s\nArtista: %s\n\n Tamanho: %llu bytes\nTempo total: %u:%02u", id3->title, id3->artist, pos, time/60, time%60];

    self.logger.text = log;
    
    self.loggerUpdaterTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                     target:self
                                   selector:@selector(updateTimer:)
                                   userInfo:nil
                                    repeats:YES];
    
}

- (void)clearLog
{
    self.logger.text = @"";
    
    [self.loggerUpdaterTimer invalidate];
    self.logger2.text = @"";
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

@end

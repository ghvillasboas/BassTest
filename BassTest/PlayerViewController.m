//
//  PlayerViewController.m
//  BassTest
//
//  Created by George Henrique Villasboas on 22/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import "PlayerViewController.h"

@interface PlayerViewController ()
@property (strong, nonatomic) NSTimer *loggerUpdaterTimer;
@end

@implementation PlayerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    BASS_INFO info;
    if (!BASS_GetInfo(&info))
        if (!BASS_Init(-1,44100,0,0,NULL))
            NSLog(@"Não foi possivel inicializar o BASS: %@", self.mp3);
    
    // Inicializa player
    // IMPORTANTE: Para mixar, o stream DEVE ser do tipo DECODE. Isso porque o Mixer usa o GetData para obter o audio
    self.channel = BASS_StreamCreateFile(FALSE, [self.mp3 cStringUsingEncoding:NSUTF8StringEncoding], 0, 0, BASS_STREAM_DECODE|BASS_SAMPLE_LOOP);
    BASS_ChannelSetAttribute(self.channel, BASS_ATTRIB_VOL,self.volumeSlider.value);
}

- (void)updateLog
{
    TAG_ID3 *id3 = (TAG_ID3*)BASS_ChannelGetTags(self.channel, BASS_TAG_ID3);
    QWORD pos = BASS_ChannelGetLength(self.channel, BASS_POS_BYTE);
    
    // A funcao BASS_ChannelGetAttribute retorna BOOL.
    // Entao passamos apenas um ponteiro para que a funcao
    // preencha o valor da variavel, certamente por ser executada
    // em thread paralela
    float volume;
    BASS_ChannelGetAttribute(self.channel, BASS_ATTRIB_VOL, &volume);
    
    int time = BASS_ChannelBytes2Seconds(self.channel, pos);
    NSString *log = [NSString stringWithFormat:@"TAGs ID3\nMusica: %s\nArtista: %s\n\nTamanho: %llu bytes\nTempo total: %u:%02u\n\nVolume: %.2f", id3->title, id3->artist, pos, time/60, time%60, volume];
    
    self.loggerInfo.text = log;
    
    if (!self.loggerUpdaterTimer) {
        // apenas para evitar que seja chamada multiplas vezes
        self.loggerUpdaterTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                 target:self
                                               selector:@selector(updateTimer:)
                                               userInfo:nil
                                                repeats:YES];
    }
}

- (void)clearLog
{
    self.loggerInfo.text = @"";
    
    [self.loggerUpdaterTimer invalidate];
    self.loggerTime.text = @"";
}

- (void)updateTimer:(NSTimer *)timer
{
    QWORD pos=BASS_ChannelGetPosition(self.channel, BASS_POS_BYTE);
    int time=BASS_ChannelBytes2Seconds(self.channel, pos);
    
    self.loggerTime.text = [NSString stringWithFormat:@"Lido: %llu bytes\nTempo total: %u:%02u", pos, time/60, time%60];
}

- (IBAction)play:(id)sender
{
    // Importante o segundo argumento. Se FALSE e o usuario parar o stream e tocar em play novamente,
    // o stream continua de onde parou, funcionando como um pause. Se TRUE, o comportamento e o esperado.
    // Ou seja, se o usuario parar o stream e tocar em play, ele reinicia.
    BASS_ChannelPlay(self.channel, TRUE);
    self.tocando = YES;
    
    [self updateLog];
}

- (IBAction)stop:(id)sender
{
    BASS_ChannelStop(self.channel);
    self.tocando = NO;
    
    [self clearLog];
}

- (IBAction)setVolume:(UISlider *)sender
{
    if (sender == self.volumeSlider) {
        BASS_ChannelSetAttribute(self.channel, BASS_ATTRIB_VOL,sender.value);
    }
    
    [self updateLog];
}
@end

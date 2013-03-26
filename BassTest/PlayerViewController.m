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
    
    self.trataErros = [[TrataErros alloc] init];
    
    BASS_INFO info;
    if (!BASS_GetInfo(&info))
        if (!BASS_Init(-1,44100,0,0,NULL))
            NSLog(@"Não foi possivel inicializar o BASS: %@", self.mp3);
    
    
    BASS_SetConfig(BASS_CONFIG_IOS_MIXAUDIO, 0);
    
    // Inicializa player
    NSLog(@"%@", self.mp3);
    // IMPORTANTE: Para mixar, o stream DEVE ser do tipo DECODE. Isso porque o Mixer usa o GetData para obter o audio
    self.channel = BASS_StreamCreateFile(FALSE, [self.mp3 cStringUsingEncoding:NSUTF8StringEncoding], 0, 0, BASS_STREAM_DECODE|BASS_SAMPLE_LOOP);
    if (![self.trataErros ocorreuErro]) {
        BASS_ChannelSetAttribute(self.channel, BASS_ATTRIB_VOL, self.volumeSlider.value);
    }

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
    NSString *log = [NSString stringWithFormat:@"%@\nTAGs ID3\nMusica: %s\nArtista: %s\n\nTamanho: %llu bytes\nTempo total: %u:%02u\n\nVolume: %.2f", self.tocando?@"PLAY":@"PAUSE", id3->title, id3->artist, pos, time/60, time%60, volume];
    
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
    self.loggerUpdaterTimer = nil;
    self.loggerTime.text = @"";
}

- (void)updateTimer:(NSTimer *)timer
{
    QWORD pos=BASS_ChannelGetPosition(self.channel, BASS_POS_BYTE);
    int time=BASS_ChannelBytes2Seconds(self.channel, pos);
    
    self.loggerTime.text = [NSString stringWithFormat:@"%@\nLido: %llu bytes\nTempo total: %u:%02u CPU: %.2f", self.tocando?@"PLAY":@"PAUSE", pos, time/60, time%60, BASS_GetCPU()];
}

- (IBAction)play:(id)sender
{
    // Importante o segundo argumento. Se FALSE e o usuario parar o stream e tocar em play novamente,
    // o stream continua de onde parou, funcionando como um pause. Se TRUE, o comportamento e o esperado.
    // Ou seja, se o usuario parar o stream e tocar em play, ele reinicia.
    //BASS_ChannelPlay(self.channel, TRUE);
    
    if (self.tocando) {
        if ([self.delegate respondsToSelector:@selector(pausar:)]) {
            [self.delegate pausar:self];
            [self.playButton setTitle:@"Resumir" forState:UIControlStateNormal];
            
//            float fft[8192]; // fft data buffer
//            BASS_ChannelGetData(self.channel, fft, BASS_DATA_FFT16384);
//            for (int a=0; a<8192; a++)
//                printf("%d: %f\n", a, fft[a]);
            
        }
    }
    else {
        if ([self.delegate respondsToSelector:@selector(tocar:)]) {
            [self.delegate tocar:self];
            [self.playButton setTitle:@"Pause" forState:UIControlStateNormal];
        }
    }
    
    self.tocando = !self.tocando;
    
    [self updateLog];
}

- (IBAction)stop:(id)sender
{
    //BASS_ChannelStop(self.channel);
    if ([self.delegate respondsToSelector:@selector(parar:)]) {
        [self.delegate parar:self];
        [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
        self.tocando = NO;
    }
    
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

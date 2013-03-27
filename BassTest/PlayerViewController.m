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
            NSLog(@"Não foi possivel inicializar o BASS: %@", self.pathToAudio);
    
    
    BASS_SetConfig(BASS_CONFIG_IOS_MIXAUDIO, 0);
    
    [self.playButton setEnabled:NO];
    [self.stopButton setEnabled:NO];
    [self.volumeSlider setEnabled:NO];
    
}

- (void)setPathToAudio:(NSString *)pathToAudio
{
    _pathToAudio = pathToAudio;
    
    // Inicializa player
    // IMPORTANTE: Para mixar, o stream DEVE ser do tipo DECODE. Isso porque o Mixer usa o GetData para obter o audio
    self.channel = BASS_StreamCreateFile(FALSE, [_pathToAudio cStringUsingEncoding:NSUTF8StringEncoding], 0, 0, BASS_STREAM_DECODE|BASS_SAMPLE_LOOP);
    if (![self.trataErros ocorreuErro]) {
        BASS_ChannelSetAttribute(self.channel, BASS_ATTRIB_VOL, self.volumeSlider.value);
        
        if ([self.delegate respondsToSelector:@selector(playerIsReady:)]) {
            [self.delegate playerIsReady:self];
            
            [self.playButton setEnabled:YES];
            [self.stopButton setEnabled:YES];
            [self.volumeSlider setEnabled:YES];
            
        }
    }
}

- (void)updateLog
{
//    TAG_ID3 *id3 = (TAG_ID3*)BASS_ChannelGetTags(self.channel, BASS_TAG_ID3);
    QWORD pos = BASS_ChannelGetLength(self.channel, BASS_POS_BYTE);
    
    // A funcao BASS_ChannelGetAttribute retorna BOOL.
    // Entao passamos apenas um ponteiro para que a funcao
    // preencha o valor da variavel, certamente por ser executada
    // em thread paralela
    float volume;
    BASS_ChannelGetAttribute(self.channel, BASS_ATTRIB_VOL, &volume);
    
    int time = BASS_ChannelBytes2Seconds(self.channel, pos);
    NSString *log = [NSString stringWithFormat:@"%@\nTAGs ID3\nMusica: \nArtista: \n\nTamanho: %llu bytes\nTempo total: %u:%02u\n\nVolume: %.2f", _isPlaying?@"PLAY":@"PAUSE", pos, time/60, time%60, volume];
    
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
    
    self.loggerTime.text = [NSString stringWithFormat:@"%@\nLido: %llu bytes\nTempo total: %u:%02u CPU: %.2f", _isPlaying?@"PLAY":@"PAUSE", pos, time/60, time%60, BASS_GetCPU()];
}

- (IBAction)tocar:(id)sender
{
    
    if (_isPlaying) {
        
        if ([self.delegate respondsToSelector:@selector(playerWillPause:)]) {
            [self.delegate playerWillPause:self];
        }
        if ([self.delegate respondsToSelector:@selector(pause:)]) {
            [self.delegate pause:self];
            _isPlaying = NO;
            [self.playButton setTitle:@"Resumir" forState:UIControlStateNormal];
            
            if ([self.delegate respondsToSelector:@selector(playerDidPause:)]) {
                [self.delegate playerDidPause:self];
            }
        }
    }
    else {
        
        [self setVolume:self.volumeSlider];
        
        if ([self.delegate respondsToSelector:@selector(playerWillPlay:)]) {
            [self.delegate playerWillPlay:self];
        }
        if ([self.delegate respondsToSelector:@selector(play:)]) {
            [self.delegate play:self];
            _isPlaying = YES;
            [self.playButton setTitle:@"Pause" forState:UIControlStateNormal];
            
            if ([self.delegate respondsToSelector:@selector(playerDidPlay:)]) {
                [self.delegate playerDidPlay:self];
            }
        }
    }
    
    [self updateLog];
}

- (IBAction)parar:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(stop:)]) {
        [self.delegate stop:self];
        [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
        _isPlaying = NO;
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

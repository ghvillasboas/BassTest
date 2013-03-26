//
//  Mixer.m
//  BassTest
//
//  Created by Edson Teco on 22/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import "Mixer.h"

@interface Mixer()

@property HSTREAM stream;
@property HENCODE encode;
@property (nonatomic, strong) TrataErros *trataErros;

@end

@implementation Mixer

#pragma mark -
#pragma mark Getters overriders

#pragma mark -
#pragma mark Setters overriders

#pragma mark -
#pragma mark Designated initializers

- (id)init
{
    self = [super init];
    if (self) {
        
        self.trataErros = [[TrataErros alloc] init];
        
        // Cria o Stream Principal
        self.stream = BASS_Mixer_StreamCreate(44100, 2, BASS_MIXER_RESUME|BASS_MIXER_NONSTOP);
        if (![self.trataErros ocorreuErro]) {
            if (BASS_ChannelPlay(self.stream, 0)) {
                NSLog(@"%@", @"Stream principal tocando");
            }
            else {
                [self.trataErros ocorreuErro];
            }
        }
    }
    return self;
}

#pragma mark -
#pragma mark Metodos publicos

- (void)tocarCanal:(HSTREAM)canal
{
    [self adicionarCanal:canal autoPlay:YES];
}

- (void)pausarCanal:(HSTREAM)canal
{
    [self removerCanal:canal];
}

- (void)resumirCanal:(HSTREAM)canal
{
    //Adiciona o canal no mixer
    [self tocarCanal:canal];
}

- (void)pararCanal:(HSTREAM)canal
{
    //Adiciona antes (sem tocar) para poder posicionar ao início antes de remover
    [self adicionarCanal:canal autoPlay:NO];

    //Posiciona para o início
    BASS_Mixer_ChannelSetPosition(canal, 0, BASS_POS_BYTE);
    if (![self.trataErros ocorreuErro]) {
        NSLog(@"%@", @"Canal reiniciado");
        
        [self removerCanal:canal];
    }
}

- (void)gravarParaArquivo:(NSString*)endereco
{
    if (BASS_Encode_IsActive(self.encode) == BASS_ACTIVE_PLAYING) {
        BASS_Encode_Stop(self.encode);
        NSLog(@"%@", @"Gravação encerrada");
    }
    else {
        
//        self.encode = BASS_Encode_StartCAFile(self.stream, 'm4af', 'alac', BASS_ENCODE_FP_16BIT, 0, [endereco cStringUsingEncoding:NSUTF8StringEncoding]);
        self.encode = BASS_Encode_StartCAFile(self.stream, 'm4af', 'aac ', BASS_ENCODE_FP_16BIT, 0, [endereco cStringUsingEncoding:NSUTF8StringEncoding]);
        if (![self.trataErros ocorreuErro]) {
            NSLog(@"%@ -> %@", @"Gravação iniciada em", endereco);
        }
    }
}

#pragma mark -
#pragma mark Metodos privados

- (void)adicionarCanal:(HSTREAM)canal autoPlay:(BOOL)autoPlay
{
    DWORD flag = 0;
    if (!autoPlay) flag = BASS_MIXER_PAUSE;
    
    //Verifica se o canal já está conectado ao mixer
    if (![self canalJaAdicionado:canal]) {
        //Adiciona o canal no mixer
        if (BASS_Mixer_StreamAddChannel(self.stream, canal, flag)) {
            NSLog(@"%@", @"Canal adicionado");
        }
        else {
            [self.trataErros ocorreuErro];
        }
    }
    else {
        // Toca caso esteja pausado
        if (autoPlay) BASS_Mixer_ChannelFlags(canal, 0, BASS_MIXER_PAUSE);
    }
}

- (void)removerCanal:(HSTREAM)canal
{
    //Remove o canal do mixer sem resetar a posição
    if (BASS_Mixer_ChannelRemove(canal)) {
        NSLog(@"%@", @"Canal pausado (removido)");
    }
    else {
        [self.trataErros ocorreuErro];
    }
}

- (BOOL)canalJaAdicionado:(HSTREAM)canal
{
    return (self.stream == BASS_Mixer_ChannelGetMixer(canal));
}

#pragma mark -
#pragma mark ViewController life cycle

#pragma mark -
#pragma mark Storyboards Segues

#pragma mark -
#pragma mark Target/Actions

#pragma mark -
#pragma mark Delegates

#pragma mark -
#pragma mark Notification center

@end

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
    //Adiciona o canal no mixer e já é executado
    if (BASS_Mixer_StreamAddChannel(self.stream, canal, 0)) {
        NSLog(@"%@", @"Canal adicionado");
    }
    else {
        [self.trataErros ocorreuErro];
    }
}

- (void)pausarCanal:(HSTREAM)canal
{
    //Remove o canal do mixer sem resetar a posição
    if (BASS_Mixer_ChannelRemove(canal)) {
        NSLog(@"%@", @"Canal pausado (removido)");
    }
    else {
        [self.trataErros ocorreuErro];
    }
}

- (void)resumirCanal:(HSTREAM)canal
{
    //Adiciona o canal no mixer
    [self tocarCanal:canal];
}

- (void)pararCanal:(HSTREAM)canal
{
    //Adiciona antes (com opção de PAUSE) para poder posicionar ao início antes de remover
    if (BASS_Mixer_StreamAddChannel(self.stream, canal, BASS_MIXER_PAUSE)) {
        NSLog(@"%@", @"Canal adicionado");
    }
    else {
        [self.trataErros ocorreuErro];
    }
    
    //Posiciona para o início
    BASS_Mixer_ChannelSetPosition(canal, 0, BASS_POS_BYTE);
    if (![self.trataErros ocorreuErro]) {
        NSLog(@"%@", @"Canal reiniciado");
        
        [self pausarCanal:canal];
    }
}

- (void)gravarParaArquivo:(NSString*)endereco
{
    if (BASS_Encode_IsActive(self.encode) == BASS_ACTIVE_PLAYING) {
        BASS_Encode_Stop(self.encode);
        NSLog(@"%@", @"Gravação encerrada");
    }
    else {
        
        self.encode = BASS_Encode_StartCAFile(self.stream, 'm4af', 'alac', BASS_ENCODE_FP_16BIT, 0, [endereco cStringUsingEncoding:NSUTF8StringEncoding]);
        if (![self.trataErros ocorreuErro]) {
            NSLog(@"%@ -> %@", @"Gravação iniciada em", endereco);
        }
    }
}

#pragma mark -
#pragma mark Metodos privados

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

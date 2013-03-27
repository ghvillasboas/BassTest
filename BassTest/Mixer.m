//
//  Mixer.m
//  BassTest
//
//  Created by Edson Teco on 22/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import "Mixer.h"

#define kSAMPLE_RATE 44100
#define kNUM_CANAIS 2
#define kRESTART_PLAYBACK 0
#define kFORMATO_ARQUIVO_GRAVACAO 'm4af'
#define kFORMATO_AUDIO_GRAVACAO 'aac ' //'alac'
#define kBITRATE_PADRAO_PARA_GRAVACAO 0
#define kPOSICAO_INICIAL 0

@interface Mixer()

@property HSTREAM stream;
@property HENCODE encode;
@property (nonatomic, strong) TrataErros *trataErros;

@end

@implementation Mixer

#pragma mark -
#pragma mark Designated initializers

- (id)init
{
    self = [super init];
    if (self) {
        
        self.trataErros = [[TrataErros alloc] init];
        
        DWORD flags = 0;
        
        // BASS_MIXER_RESUME:   When stalled, resume the mixer immediately
        //                      upon a source being added or unpaused,
        //                      else it will be resumed at the next update cycle.
        // BASS_MIXER_NONSTOP:  Do not stop producing output when there are
        //                      no active source channels, else it will be
        //                      stalled until there are active sources.
        flags = BASS_MIXER_RESUME|BASS_MIXER_NONSTOP;
        
        // Cria o Stream Principal do Mixer
        self.stream = BASS_Mixer_StreamCreate(kSAMPLE_RATE,
                                              kNUM_CANAIS,
                                              flags);
        if (![self.trataErros ocorreuErro]) {
            // Começa a tocar o stream principal
            if (BASS_ChannelPlay(self.stream,
                                 kRESTART_PLAYBACK)) {
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

/*!
 * Método utilizado para tocar um canal no mixer
 * @param HSTREAM canal Handler do canal que deseja ser tocado
 *
 * @since 1.0.0
 * @author Logics Software
 */
- (void)tocarCanal:(HSTREAM)canal
{
    [self adicionarCanal:canal autoPlay:YES];
}

/*!
 * Método utilizado para pausar um canal no mixer
 * @param HSTREAM canal Handler do canal que deseja ser pausado
 *
 * @since 1.0.0
 * @author Logics Software
 */
- (void)pausarCanal:(HSTREAM)canal
{
    [self removerCanal:canal];
}

/*!
 * Método utilizado para continuar a tocar um canal após ser pausado
 * @param HSTREAM canal Handler do canal que deseja ser continuado
 *
 * @since 1.0.0
 * @author Logics Software
 */
- (void)resumirCanal:(HSTREAM)canal
{
    [self tocarCanal:canal];
}

/*!
 * Método utilizado para parar de tocar um canal
 * @param HSTREAM canal Handler do canal que deseja ser parado
 *
 * @since 1.0.0
 * @author Logics Software
 */
- (void)pararCanal:(HSTREAM)canal
{
    //Adiciona antes (sem tocar) para poder posicionar ao início antes de remover
    [self adicionarCanal:canal autoPlay:NO];

    //Posiciona para o início
    BASS_Mixer_ChannelSetPosition(canal,
                                  kPOSICAO_INICIAL,
                                  BASS_POS_BYTE);
    if (![self.trataErros ocorreuErro]) {
        NSLog(@"%@", @"Canal reiniciado");
        
        [self removerCanal:canal];
    }
}

/*!
 * Método utilizado para gravar/parar todo o audio que está sendo tocado no mixer.
 * @param NSString caminho Caminho completo do arquivo que deseja ser gravado
 *
 * @since 1.0.0
 * @author Logics Software
 */
- (void)gravarParaArquivo:(NSString*)caminho
{
    // Se o mixer estiver gravando, pára a gravação
    if (BASS_Encode_IsActive(self.encode) == BASS_ACTIVE_PLAYING) {
        BASS_Encode_Stop(self.encode);
        NSLog(@"%@", @"Gravação encerrada");
    }
    else {
        // Inicia a função de gravação. Pode ser utilizado 'alac' ou 'aac ' para o formato do audio
        self.encode = BASS_Encode_StartCAFile(self.stream,
                                              kFORMATO_ARQUIVO_GRAVACAO,
                                              kFORMATO_AUDIO_GRAVACAO,
                                              BASS_ENCODE_FP_16BIT,
                                              kBITRATE_PADRAO_PARA_GRAVACAO,
                                              [caminho cStringUsingEncoding:NSUTF8StringEncoding]);
        if (![self.trataErros ocorreuErro]) {
            NSLog(@"%@ -> %@", @"Gravação iniciada em", caminho);
        }
    }
}

#pragma mark -
#pragma mark Metodos privados

/*!
 * Método para adicionar um canal no mixer. Este método já verifica se o canal está adicionado e faz o tratamento
 * @param HSTREAM canal Handler do canal que deseja ser adicionado ao mixer
 * @param BOOL autoPlay Se YES, o canal é adicionado e já inicia a tocar. Se NO, apenas é adicionado no mixer.
 *
 * @since 1.0.0
 * @author Logics Software
 */
- (void)adicionarCanal:(HSTREAM)canal autoPlay:(BOOL)autoPlay
{
    DWORD flags = 0;
    if (!autoPlay) flags = BASS_MIXER_PAUSE|BASS_MIXER_DOWNMIX;
    
    //Verifica se o canal já está conectado ao mixer
    if (![self canalJaAdicionado:canal]) {
        //Adiciona o canal no mixer
        if (BASS_Mixer_StreamAddChannel(self.stream, canal, flags)) {
            NSLog(@"%@", @"Canal adicionado");
        }
        else {
            [self.trataErros ocorreuErro];
        }
    }
    else {
        // Toca caso esteja pausado e já adicionado
        if (autoPlay) BASS_Mixer_ChannelFlags(canal, FALSE, BASS_MIXER_PAUSE);
    }
}

/*!
 * Método para remover um canal do mixer.
 * @param HSTREAM canal Handler do canal que deseja ser removido do mixer
 *
 * @since 1.0.0
 * @author Logics Software
 */
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

/*!
 * Método para verificar se um canal já está adicionado no mixer
 * @param HSTREAM canal Handler do canal que deseja verificar se já está adicionado no mixer
 * @return BOOL retorna YES se já está adicionado
 *
 * @since 1.0.0
 * @author Logics Software
 */
- (BOOL)canalJaAdicionado:(HSTREAM)canal
{
    return (self.stream == BASS_Mixer_ChannelGetMixer(canal));
}

@end

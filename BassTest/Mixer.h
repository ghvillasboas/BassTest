//
//  Mixer.h
//  BassTest
//
//  Created by Edson Teco on 22/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TrataErros.h"
#import "bass.h"
#import "bassenc.h"
#import "bassmix.h"

@interface Mixer : NSObject

- (void)tocarCanal:(HSTREAM)canal;
- (void)pausarCanal:(HSTREAM)canal;
- (void)resumirCanal:(HSTREAM)canal;
- (void)pararCanal:(HSTREAM)canal;
- (void)gravarParaArquivo:(NSString*)endereco;

@end

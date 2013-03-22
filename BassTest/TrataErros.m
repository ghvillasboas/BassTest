//
//  TrataErros.m
//  BassTest
//
//  Created by Edson Teco on 22/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import "TrataErros.h"

@implementation TrataErros

- (id)init
{
    self = [super init];
    if (self) {
        self.codigos = [[NSDictionary alloc] initWithObjects:@[@"BASS_OK",
                        @"BASS_ERROR_MEM",
                        @"BASS_ERROR_FILEOPEN",
                        @"BASS_ERROR_DRIVER",
                        @"BASS_ERROR_BUFLOST",
                        @"BASS_ERROR_HANDLE",
                        @"BASS_ERROR_FORMAT",
                        @"BASS_ERROR_POSITION",
                        @"BASS_ERROR_INIT",
                        @"BASS_ERROR_START",
                        @"BASS_ERROR_ALREADY",
                        @"BASS_ERROR_NOCHAN",
                        @"BASS_ERROR_ILLTYPE",
                        @"BASS_ERROR_ILLPARAM",
                        @"BASS_ERROR_NO3D",
                        @"BASS_ERROR_NOEAX",
                        @"BASS_ERROR_DEVICE",
                        @"BASS_ERROR_NOPLAY",
                        @"BASS_ERROR_FREQ",
                        @"BASS_ERROR_NOTFILE",
                        @"BASS_ERROR_NOHW",
                        @"BASS_ERROR_EMPTY",
                        @"BASS_ERROR_NONET",
                        @"BASS_ERROR_CREATE",
                        @"BASS_ERROR_NOFX",
                        @"BASS_ERROR_NOTAVAIL",
                        @"BASS_ERROR_DECODE",
                        @"BASS_ERROR_DX",
                        @"BASS_ERROR_TIMEOUT",
                        @"BASS_ERROR_FILEFORM",
                        @"BASS_ERROR_SPEAKER",
                        @"BASS_ERROR_VERSION",
                        @"BASS_ERROR_CODEC",
                        @"BASS_ERROR_ENDED",
                        @"BASS_ERROR_BUSY",
                        @"BASS_ERROR_UNKNOWN"]
                                                     forKeys:@[@0,
                        @1,
                        @2,
                        @3,
                        @4,
                        @5,
                        @6,
                        @7,
                        @8,
                        @9,
                        @14,
                        @18,
                        @19,
                        @20,
                        @21,
                        @22,
                        @23,
                        @24,
                        @25,
                        @27,
                        @29,
                        @31,
                        @32,
                        @33,
                        @34,
                        @37,
                        @38,
                        @39,
                        @40,
                        @41,
                        @42,
                        @43,
                        @44,
                        @45,
                        @46,
                        @-1]];
    }
    return self;
}

- (BOOL)ocorreuErro
{
    int codigo = BASS_ErrorGetCode();
    
    if (codigo == 0) {
        return NO;
    }
    else {
        NSLog(@"Erro: %@", [self.codigos objectForKey:[NSNumber numberWithInt:codigo]]);
        return YES;
    }
}

@end


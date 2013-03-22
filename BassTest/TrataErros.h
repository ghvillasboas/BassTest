//
//  TrataErros.h
//  BassTest
//
//  Created by Edson Teco on 22/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "bass.h"
#import "bassenc.h"
#import "bassmix.h"

@interface TrataErros : NSObject

@property (nonatomic, strong) NSDictionary *codigos;

- (BOOL)ocorreuErro;

@end

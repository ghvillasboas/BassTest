//
//  BassTestViewController.m
//  BassTest
//
//  Created by George Henrique Villasboas on 21/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import "BassTestViewController.h"

@interface BassTestViewController ()

@end

@implementation BassTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.player1 = [[PlayerViewController alloc] init];
    self.player1.mp3 = [[NSBundle mainBundle] pathForResource:@"audio1" ofType:@"mp3"];
    self.player1.delegate = self;
    
    [self addChildViewController:self.player1];
    [self.holderPlayer1 addSubview:self.player1.view];
    [self.player1 didMoveToParentViewController:self];
    
    self.vinil = [[ScratcherViewController alloc] init];
    self.vinil.mp3 = [[NSBundle mainBundle] pathForResource:@"audio2" ofType:@"mp3"];
    [self addChildViewController:self.vinil];
    [self.holderPlayer2 addSubview:self.vinil.view];
    
    self.vinil.delegate = self;
    
    self.mixer = [[Mixer alloc] init];

}

- (IBAction)recGeral:(id)sender
{
    // Arquivo de saída
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *file = [documentsDirectory stringByAppendingPathComponent:@"output.m4a"];
    [self.mixer gravarParaArquivo:file];
}

- (void)tocar:(PlayerViewController *)requestor
{
    [self.mixer tocarCanal:requestor.channel];
}

- (void)pausar:(PlayerViewController *)requestor
{
    if (requestor.tocando) {
        [self.mixer pausarCanal:requestor.channel];
    }
    else {
        [self.mixer resumirCanal:requestor.channel];
    }
}

- (void)parar:(PlayerViewController *)requestor
{
    [self.mixer pararCanal:requestor.channel];
}

//----------

- (void)tocarScratcher:(ScratcherViewController*)requestor
{
    [self.mixer tocarCanal:requestor.channel];
}

- (void)pausarScratcher:(ScratcherViewController *)requestor
{
    if (requestor.tocando) {
        [self.mixer pausarCanal:requestor.channel];
    }
    else {
        [self.mixer resumirCanal:requestor.channel];
    }
}

- (void)pararScratcher:(ScratcherViewController*)requestor
{
    [self.mixer pararCanal:requestor.channel];
}

@end

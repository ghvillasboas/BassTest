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

#pragma mark -
#pragma mark Getters overriders

#pragma mark -
#pragma mark Setters overriders

#pragma mark -
#pragma mark Designated initializers

#pragma mark -
#pragma mark Metodos publicos

#pragma mark -
#pragma mark Metodos privados

#pragma mark -
#pragma mark ViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self.recGeralButton setEnabled:NO];
    
//    self.player1 = [[PlayerViewController alloc] init];
//    self.player1.delegate = self;
//    
//    [self addChildViewController:self.player1];
//    [self.holderPlayer1 addSubview:self.player1.view];
    
    self.vinil = [[ScratcherViewController alloc] init];
    [self addChildViewController:self.vinil];
    [self.holderPlayer1 addSubview:self.vinil.view];
    
    self.vinil.delegate = self;
    
    self.mixer = [[Mixer alloc] init];
    
}

#pragma mark -
#pragma mark Storyboards Segues

#pragma mark -
#pragma mark Target/Actions

- (IBAction)recGeral:(id)sender
{
    // Arquivo de saída
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *file = [documentsDirectory stringByAppendingPathComponent:@"output.m4a"];
    [self.mixer gravarParaArquivo:file];
}

#pragma mark -
#pragma mark Delegates

#pragma mark PlayerProtocol

-(void)playerIsReady:(id<PlayerDataSource>)player
{
    [self.recGeralButton setEnabled:YES];
}

-(void)play:(id<PlayerDataSource>)player
{
    [self.mixer tocarCanal:player.channel];
}

-(void)pause:(id<PlayerDataSource>)player
{
    if (player.isPlaying) {
        [self.mixer pausarCanal:player.channel];
    }
    else {
        [self.mixer resumirCanal:player.channel];
    }
}

-(void)stop:(id<PlayerDataSource>)player
{
    [self.mixer pararCanal:player.channel];
}

@end

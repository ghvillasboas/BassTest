//
//  BassTestViewController.m
//  BassTest
//
//  Created by George Henrique Villasboas on 21/03/13.
//  Copyright (c) 2013 George Henrique Villasboas. All rights reserved.
//

#import "BassTestViewController.h"

@interface BassTestViewController ()

@property (nonatomic, strong) UIImage* rotulo;

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

- (void)adicionaMusicaComPath:(NSString*)path
{
    if (self.scratcherViewController) {
        [self parar:nil];
        [self.scratcherViewController.view removeFromSuperview];
        [self.scratcherViewController removeFromParentViewController];
        [self.scratcherViewController free];
        self.scratcherViewController = nil;
    }
    self.scratcherViewController = [[ScratcherViewController alloc] init];
    [self addChildViewController:self.scratcherViewController];
    [self.holderPlayer1 addSubview:self.scratcherViewController.view];
    self.scratcherViewController.delegate = self;
    [self.scratcherViewController setPathToAudio:path];
    [self.scratcherViewController setArtWork:self.rotulo];
}

- (void)showMediaPicker
{
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAnyAudio];

    [[picker view] setFrame:CGRectMake(0, 0, 320, 480)];

    picker.delegate = self;
    picker.allowsPickingMultipleItems = NO;

    [self presentViewController:picker animated:YES completion:nil];
}

- (void)obtemInformacoes:(MPMediaItemCollection *)collection
{
    if (collection.count == 1) {
        
        NSArray *items = collection.items;
        MPMediaItem *mediaItem =  [items objectAtIndex:0];
        if ([mediaItem isKindOfClass:[MPMediaItem class]]) {
            
            NSString *titulo = [mediaItem valueForProperty:MPMediaItemPropertyTitle];
            MPMediaItemArtwork *artwork = [mediaItem valueForProperty:MPMediaItemPropertyArtwork];
            NSURL *url = [mediaItem valueForProperty:MPMediaItemPropertyAssetURL];
            
            if (artwork) {
                self.rotulo = [artwork imageWithSize:CGSizeMake(75, 75)];
            }
            else {
                debug(@"%@", artwork);
            }
            
            NSLog(@"%@", titulo);
            NSLog(@"%@", url);
            
        }
    }
}

- (void)exportAssetAsSourceFormat:(MPMediaItem *)item
{
    NSURL *assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                           initWithAsset:songAsset
                                           presetName:AVAssetExportPresetPassthrough];
    
    NSArray *tracks = [songAsset tracksWithMediaType:AVMediaTypeAudio];
    AVAssetTrack *track = [tracks objectAtIndex:0];
    
    id desc = [track.formatDescriptions objectAtIndex:0];
    const AudioStreamBasicDescription *audioDesc = CMAudioFormatDescriptionGetStreamBasicDescription((__bridge CMAudioFormatDescriptionRef)desc);
    FourCharCode formatID = audioDesc->mFormatID;
    
    NSString *fileType = nil;
    NSString *extensao = nil;
    
    switch (formatID) {
            
        case kAudioFormatLinearPCM: {
            UInt32 flags = audioDesc->mFormatFlags;
            if (flags & kAudioFormatFlagIsBigEndian) {
                fileType = @"public.aiff-audio";
                extensao = @"aif";
            } else {
                fileType = @"com.microsoft.waveform-audio";
                extensao = @"wav";
            }
        }
            break;
            
        case kAudioFormatMPEGLayer3:
            fileType = @"com.apple.quicktime-movie";
            extensao = @"mov"; //mp3
            break;
            
        case kAudioFormatMPEG4AAC:
            fileType = @"com.apple.m4a-audio";
            extensao = @"m4a";
            break;
            
        case kAudioFormatAppleLossless:
            fileType = @"com.apple.m4a-audio";
            extensao = @"m4a";
            break;
            
        default:
            break;
    }
    
    exportSession.outputFileType = fileType;
    
    NSString *fileName = [NSString stringWithString:[item valueForProperty:MPMediaItemPropertyTitle]];
    NSArray *fileNameArray = [fileName componentsSeparatedByString:@" "];
    fileName = [fileNameArray componentsJoinedByString:@""];
    
    NSString *filePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:extensao];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [self performSelectorOnMainThread:@selector(adicionaMusicaComPath:) withObject:filePath waitUntilDone:NO];
        return;
    }
    else {
        
        myDeleteFile(filePath);
        exportSession.outputURL = [NSURL fileURLWithPath:filePath];
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                debug(@"export ok");
                
                [self performSelectorOnMainThread:@selector(adicionaMusicaComPath:) withObject:filePath waitUntilDone:NO];
            } else {
                debug(@"export session error");
                
                if (exportSession.status == AVAssetExportSessionStatusFailed) {
                    debug(@"%@", exportSession.error.localizedDescription);
                }
            }
        }];
    }
}

void myDeleteFile (NSString* path)
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *deleteErr = nil;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&deleteErr];
        if (deleteErr) {
            debug(@"Can't delete %@: %@", path, deleteErr);
        }
    }
}

#pragma mark -
#pragma mark ViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self.recGeralButton setEnabled:NO];

    self.mixer = [[Mixer alloc] init];
}

#pragma mark -
#pragma mark Storyboards Segues

#pragma mark -
#pragma mark Target/Actions

-(IBAction)selecionarMusica:(id)sender
{
    [self showMediaPicker];
}

-(IBAction)tocar:(id)sender
{
    if (self.scratcherViewController.isLoaded) {
        if (self.scratcherViewController.isPlaying) {

            [self pause:self.scratcherViewController];
            self.scratcherViewController.isPlaying = NO;
            self.scratcherViewController.isOn = NO;
            
            [self.powerButton setImage:[UIImage imageNamed:@"pickupBotaoLigar-on"] forState:UIControlStateNormal];

        }
        else {
            
//            [self.scratcherViewController.volume = volumeSlider];
            
            [self play:self.scratcherViewController];
            self.scratcherViewController.isPlaying = YES;
            self.scratcherViewController.isOn = YES;

            [self.powerButton setImage:[UIImage imageNamed:@"pickupBotaoLigar-off"] forState:UIControlStateNormal];
        }
    }
    else {
        [self showMediaPicker];
    }
}

-(IBAction)parar:(id)sender
{
    [self stop:self.scratcherViewController];

    [self.scratcherViewController stop];
    self.scratcherViewController.isPlaying = NO;
    self.scratcherViewController.isOn = NO;
}

- (IBAction)recGeral:(id)sender
{
    // Arquivo de saída
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *file = [documentsDirectory stringByAppendingPathComponent:@"output.m4a"];
    [self.mixer gravarParaArquivo:file];
}

#pragma mark -
#pragma mark Delegates

#pragma mark MPMediaPickerControllerDelegate

-(void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:^{
        debug(@"Cancelado");
    }];
}

-(void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self obtemInformacoes:mediaItemCollection];
        [self exportAssetAsSourceFormat:[[mediaItemCollection items] objectAtIndex:0]];
    }];
}

#pragma mark PlayerProtocol

-(void)playerIsReady:(id<PlayerDataSource>)player
{
    [self.recGeralButton setEnabled:YES];
    [self tocar:nil];
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

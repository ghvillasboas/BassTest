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
    self.scratcherViewController = [[ScratcherViewController alloc] initWithFrame:self.holderPlayer1.frame];
    [self addChildViewController:self.scratcherViewController];
    [self.holderPlayer1 addSubview:self.scratcherViewController.view];
    self.scratcherViewController.delegate = self;
    [self.scratcherViewController setPathToAudio:path];
    [self.scratcherViewController setArtWork:self.rotulo];
    
    [self.selectButton setImage:[UIImage imageNamed:@"pickupBotaoAdicionarMusica-on"] forState:UIControlStateNormal];
}

- (void)showMediaPicker
{
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAnyAudio];

    [[picker view] setFrame:self.view.frame];

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
            
            if (artwork != nil) {
                self.rotulo = [artwork imageWithSize:CGSizeMake(75, 75)];
                
                if (!self.rotulo) {
                    self.rotulo = [UIImage imageNamed:@"pickupRotuloDeck"];
                }
            }
            else {
                self.rotulo = [UIImage imageNamed:@"pickupRotuloDeck"];
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

-(void)updateDisplay:(NSTimer*)timer
{
    self.progressLabel.text = [NSString stringWithFormat:@"%02u:%02u", self.scratcherViewController.progress/60, self.scratcherViewController.progress%60];
}

#pragma mark -
#pragma mark ViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self.recGeralButton setEnabled:NO];

    self.mixer = [[Mixer alloc] init];
    
    self.updateProgress = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                           target:self
                                                         selector:@selector(updateDisplay:)
                                                         userInfo:nil
                                                          repeats:YES];
    
    UIImage *minImage = [UIImage imageNamed:@"empty"];
    UIImage *maxImage = [UIImage imageNamed:@"empty"];
    UIImage *tumbImage= [UIImage imageNamed:@"pickupFader"];
    [self.volumeSlider setMinimumTrackImage:minImage forState:UIControlStateNormal];
    [self.volumeSlider setMaximumTrackImage:maxImage forState:UIControlStateNormal];
    [self.volumeSlider setThumbImage:tumbImage forState:UIControlStateNormal];
    
    [self.selectButton setImage:[UIImage imageNamed:@"pickupBotaoAdicionarMusica-off"] forState:UIControlStateNormal];
    [self.powerButton setImage:[UIImage imageNamed:@"pickupBotaoLigar-off"] forState:UIControlStateNormal];
    
}

#pragma mark -
#pragma mark Storyboards Segues

#pragma mark -
#pragma mark Target/Actions

-(IBAction)defineVolume:(id)sender
{
    self.scratcherViewController.volume = self.volumeSlider.value;
}

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
            
            [self.powerButton setImage:[UIImage imageNamed:@"pickupBotaoLigar-off"] forState:UIControlStateNormal];

        }
        else {
            
            self.scratcherViewController.volume = self.volumeSlider.value;
            
            [self play:self.scratcherViewController];
            self.scratcherViewController.isPlaying = YES;
            self.scratcherViewController.isOn = YES;

            [self.powerButton setImage:[UIImage imageNamed:@"pickupBotaoLigar-on"] forState:UIControlStateNormal];
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
        
        [self.selectButton setImage:[UIImage imageNamed:@"pickupBotaoAdicionarMusica-on"] forState:UIControlStateNormal];
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

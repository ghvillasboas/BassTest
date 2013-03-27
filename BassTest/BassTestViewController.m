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

- (void)obtemInformacoes:(MPMediaItemCollection *)collection
{
    if (collection.count == 1) {
        
        NSArray *items = collection.items;
        MPMediaItem *mediaItem =  [items objectAtIndex:0];
        if ([mediaItem isKindOfClass:[MPMediaItem class]]) {
            
            //NSString *titulo = [mediaItem valueForProperty:MPMediaItemPropertyTitle];
            //MPMediaItemPropertyArtwork
            
            NSURL *url = [mediaItem valueForProperty:MPMediaItemPropertyAssetURL];
            NSLog(@"%@", url);
            
            //            AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:url];
            //            AVMutableAudioMix *fadeMix = [AVMutableAudioMix audioMix];
            //            AVMutableAudioMixInputParameters *params = [AVMutableAudioMixInputParameters audioMixInputParameters];
            //            [params setVolumeRampFromStartVolume:0 toEndVolume:1 timeRange:
            //             CMTimeRangeMake(CMTimeMakeWithSeconds(0, 1), CMTimeMakeWithSeconds(5,1))];
            //            [fadeMix setInputParameters:[NSArray arrayWithObject:params]];
            //            [playerItem setAudioMix:fadeMix];
            //            AVPlayer *newAvPlayer = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            //            [newAvPlayer play];
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
    
    NSLog(@"filePath = %@", filePath);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [self.vinil setPathToAudio:filePath];
        [self.player1 setMp3:filePath];
        return;
    }
    else {
        
        myDeleteFile(filePath);
        exportSession.outputURL = [NSURL fileURLWithPath:filePath];
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                NSLog(@"export session completed");
                
                [self.vinil setPathToAudio:filePath];
                [self.player1 setMp3:filePath];
            } else {
                NSLog(@"export session error");
                
                if (exportSession.status == AVAssetExportSessionStatusFailed) {
                    NSLog(@"%@", exportSession.error.localizedDescription);
                }
            }
        }];
    }
}

void myDeleteFile (NSString* path) {
    //  NSLog(@"file path delete file :::::::::: %@", path);
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *deleteErr = nil;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&deleteErr];
        if (deleteErr) {
            NSLog (@"Can't delete %@: %@", path, deleteErr);
        }
    }
}


#pragma mark -
#pragma mark ViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self.recGeralButton setEnabled:NO];
    
    self.player1 = [[PlayerViewController alloc] init];
    self.player1.mp3 = [[NSBundle mainBundle] pathForResource:@"audio1" ofType:@"mp3"];
    //self.player1.mp3 = [[NSBundle mainBundle] pathForResource:@"audio3" ofType:@"m4a"];
    self.player1.delegate = self;
    
    [self addChildViewController:self.player1];
    [self.holderPlayer1 addSubview:self.player1.view];
    
    self.vinil = [[ScratcherViewController alloc] init];
    [self addChildViewController:self.vinil];
    [self.holderPlayer2 addSubview:self.vinil.view];
    
    self.vinil.delegate = self;
    
    self.mixer = [[Mixer alloc] init];
    
}

#pragma mark -
#pragma mark Storyboards Segues

#pragma mark -
#pragma mark Target/Actions

- (IBAction)showMediaPicker:(id)sender
{
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAnyAudio];
    
    [[picker view] setFrame:CGRectMake(0, 0, 320, 480)];
    
    picker.delegate = self;
    picker.allowsPickingMultipleItems = NO;
    picker.prompt = NSLocalizedString (@"AddSongsPrompt", @"Prompt to user to choose some songs to play");
    
    [self presentViewController:picker animated:YES completion:^{
    }];
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

-(void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self exportAssetAsSourceFormat:[[mediaItemCollection items] objectAtIndex:0]];
        
        [self obtemInformacoes:mediaItemCollection];
    }];
}

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

#pragma mark PlayerDelegate

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

@end

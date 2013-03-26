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
    //self.player1.mp3 = [[NSBundle mainBundle] pathForResource:@"audio3" ofType:@"m4a"];
    self.player1.delegate = self;
    
    [self addChildViewController:self.player1];
    [self.holderPlayer1 addSubview:self.player1.view];
    //[self.player1 didMoveToParentViewController:self];
    
    self.vinil = [[ScratcherViewController alloc] init];
//    self.vinil.mp3 = [[NSBundle mainBundle] pathForResource:@"audio4" ofType:@"m4a"];
//    self.vinil.mp3 = [[NSBundle mainBundle] pathForResource:@"audio2" ofType:@"mp3"];
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


//----------------------------------------------------------------------------

- (IBAction)showMediaPicker:(id)sender
{
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAnyAudio];
    
    [[picker view] setFrame:CGRectMake(0, 0, 320, 480)];
    
    picker.delegate      = self;
    picker.allowsPickingMultipleItems = NO;
    picker.prompt      = NSLocalizedString (@"AddSongsPrompt", @"Prompt to user to choose some songs to play");
    
    [self presentViewController:picker animated:YES completion:^{
    }];
}


- (void) playSelectedMediaCollection: (MPMediaItemCollection *) collection {
    
    if (collection.count == 1) {
        
        
        [self exportAssetAsSourceFormat:[[collection items] objectAtIndex:0]];
        
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

- (void)exportAssetAsSourceFormat:(MPMediaItem *)item {
    
    //  [self showLoadingView];
    
    NSLog(@"export asset called");
    NSURL *assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
    NSLog(@"\n>>>> assetURL : %@",[assetURL absoluteString]);
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    
    // JP
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                           initWithAsset:songAsset
                                           presetName:AVAssetExportPresetPassthrough];
    
    NSArray *tracks = [songAsset tracksWithMediaType:AVMediaTypeAudio];
    AVAssetTrack *track = [tracks objectAtIndex:0];
    
    id desc = [track.formatDescriptions objectAtIndex:0];
    const AudioStreamBasicDescription *audioDesc = CMAudioFormatDescriptionGetStreamBasicDescription((__bridge CMAudioFormatDescriptionRef)desc);
    FourCharCode formatID = audioDesc->mFormatID;
    
    //exportAudioMix.inputParameters = [NSArray arrayWithObject:exportAudioMixInputParameters];
    //exportSession.audioMix = exportAudioMix;
    
    NSString *fileType = nil;
    NSString *ex = nil;
    
    switch (formatID) {
            
        case kAudioFormatLinearPCM:
        {
            UInt32 flags = audioDesc->mFormatFlags;
            if (flags & kAudioFormatFlagIsBigEndian) {
                fileType = @"public.aiff-audio";
                ex = @"aif";
            } else {
                fileType = @"com.microsoft.waveform-audio";
                ex = @"wav";
            }
        }
            break;
            
        case kAudioFormatMPEGLayer3:
            fileType = @"com.apple.quicktime-movie";
            ex = @"mov";
            break;
            
        case kAudioFormatMPEG4AAC:
            fileType = @"com.apple.m4a-audio";
            ex = @"m4a";
            break;
            
        case kAudioFormatAppleLossless:
            fileType = @"com.apple.m4a-audio";
            ex = @"m4a";
            break;
            
        default:
            break;
    }
    
    exportSession.outputFileType = fileType;
    
    NSString *fileName = nil;
    
    fileName = [NSString stringWithString:[item valueForProperty:MPMediaItemPropertyTitle]];
    //fileName = [[fileName stringByAppendingString:@"-"] stringByAppendingString:[item valueForProperty:MPMediaItemPropertyArtist]];
    NSArray *fileNameArray = nil;
    fileNameArray = [fileName componentsSeparatedByString:@" "];
    fileName = [fileNameArray componentsJoinedByString:@""];
    
    NSLog(@">>>>> fileName = %@", fileName);
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [[docDir stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:ex];
    
    NSLog(@"filePath = %@", filePath);
    
    
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        //        //NSLog(@"file exist::::::::::==============>>>>>>>>>>>>>>>>>");
        //        counterIpod--;
        //
        //        if(counterIpod == 0) {
        //            //[self showAlertView];
        //            //[self hideLoadingView];
        //        }
        //
        //        NSString *str = [NSString stringWithFormat:@"Loading %d of %d Beats", totalcollection - counterIpod ,totalcollection];
        //        [lbl performSelectorOnMainThread:@selector(setText:) withObject:str waitUntilDone:NO];
        //        //NSLog(@"loading string : %@", str);
        
        [self.vinil setMp3:filePath];
        [self.player1 setMp3:filePath];
        return;
    }
    
    NSLog(@"file not exist  ===========>>>>>>>>>");
    // -------------------------------------
    int fileNumber = 0;
    NSString *fileNumberString = nil;
    NSString *fileNameWithNumber = nil;
    while ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        fileNumber++;
        fileNumberString = [NSString stringWithFormat:@"-%02d", fileNumber];
        fileNameWithNumber = [fileName stringByAppendingString:fileNumberString];
        filePath = [[docDir stringByAppendingPathComponent:fileNameWithNumber] stringByAppendingPathExtension:ex];
        NSLog(@"filePath = %@", filePath);
    }
    
    // -------------------------------------
    myDeleteFile(filePath);
    exportSession.outputURL = [NSURL fileURLWithPath:filePath];
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"export session completed");
            
            [self.vinil setMp3:filePath];
            [self.player1 setMp3:filePath];
            
            //            counterIpod--;
            //
            //            NSString *str = [NSString stringWithFormat:@"Loading %d of %d Beats", totalcollection - counterIpod ,totalcollection];
            //
            //            //[self performSelector:@selector(setLabelText:) withObject:str afterDelay:0.02];
            //            [lbl performSelectorOnMainThread:@selector(setText:) withObject:str waitUntilDone:NO];
            //            NSLog(@"loading string : %@", str);
            //
            //            if(counterIpod == 0) {
            //                //[self showAlertView];
            //                //[self hideLoadingView];
            //            }
        } else {
            NSLog(@"export session error");
            
            if (exportSession.status == AVAssetExportSessionStatusFailed) {
                NSLog(@"%@", exportSession.error.localizedDescription);
            }
            
            //            counterIpod--;
            //            NSString *str = [NSString stringWithFormat:@"Loading %d of %d Beats", totalcollection - counterIpod ,totalcollection];
            //            [lbl performSelectorOnMainThread:@selector(setText:) withObject:str waitUntilDone:NO];
            //            //return NO;
            //            if(counterIpod == 0) {
            //                //[self showAlertView];
            //                //[self hideLoadingView];
            //            }
        }
        
        //        [exportSession release];
    }];
    
    //[appDelegate hideLoadingView];
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

#pragma mark Delegates

-(void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    [self dismissViewControllerAnimated:YES completion:^{
        
        NSLog(@"%@", mediaItemCollection);
        
        [self playSelectedMediaCollection: mediaItemCollection];
        
    }];
    
}

@end

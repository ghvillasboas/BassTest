//
//  AudioScratchDemoViewController.mm
//  AudioScratchDemo
//
//  Created by Jan Kalis on 10/22/10.
//  Copyright 2010 Jan Kalis Glow Interactive. All rights reserved.
//
#import "ScratcherViewController.h"
#import "TrataErros.h"
#import <sys/stat.h>
#import <sys/mman.h>
#import <fcntl.h>
#import <pthread.h>
#import <sys/time.h>
#import <time.h>
#import <QuartzCore/CALayer.h>
#import "Scratcher.h"

#define BYTE_POSITION_TO_PIXELS 0.00001f
#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
#define kAJUSTE_MEMORIA_ADICIONAL 400000

#define kSTREAM_FROM_MEMORY FALSE
#define kOFFSET_DO_INICIO 0
#define kTAMANHO_DOS_DADOS 0

struct Info
{
    HSTREAM decoder;
    void* data;
} info;

@interface ScratcherViewController()
@property (strong, nonatomic) Scratcher* scratcher;
@property HSTREAM handle;
@property (strong, nonatomic) NSTimer* updateTimer;
@property float prevAngle;
@property float angleAccum;
@property float initialScratchPosition;
@property HSTREAM decoder;
@property FILE* mappedFile;
@property void* mappedMemory;
@property QWORD mappedMemorySize;
@property double firstGetSeconds;
@property (strong, nonatomic) NSTimer *loggerUpdaterTimer;
@end

@implementation ScratcherViewController

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
	fclose(self.mappedFile);
	munmap(self.mappedMemory, self.mappedMemorySize);
}

#pragma mark -
#pragma mark Getters overriders

- (HSTREAM)channel
{
    return self.scratcher.soundTrackScratchStreamHandle;
}

-(float)bpm
{
    // Obtem o BPM
    if (![_pathToAudio isEqualToString:@""]) {
        float playBackDuration = BASS_ChannelBytes2Seconds(self.decoder,
                                                           BASS_ChannelGetLength(self.decoder, BASS_POS_BYTE));
        float BpmValue = BASS_FX_BPM_DecodeGet(self.decoder,
                                               kOFFSET_DO_INICIO,
                                               playBackDuration,
                                               MAKELONG(45,256),
                                               BASS_FX_BPM_MULT2|BASS_FX_BPM_MULT2|BASS_FX_FREESOURCE,
                                               NULL,
                                               NULL);
        return BpmValue;
    }
    return 0;
}

#pragma mark -
#pragma mark Setters overriders

- (void)setIsPlaying:(BOOL)isPlaying
{
    _isPlaying = isPlaying;
    
    if (_isPlaying) {
        [self.PlayButton setImage:[UIImage imageNamed:@"pickupBotaoLigar-on"] forState:UIControlStateNormal];
        
        // Se o timeOffset for 0.0, inicializa a animação
        if (self.imgBrilho.layer.timeOffset == 0.0) {
            [self animaBrilho:self.imgBrilho];
        }
        // Se for diferente de 0.0, resume
        else {
            [self resumeLayer:self.imgBrilho.layer];
        }
    }
    else {
        [self.PlayButton setImage:[UIImage imageNamed:@"pickupBotaoLigar-off"] forState:UIControlStateNormal];
        [self pauseLayer:self.imgBrilho.layer];
    }
}

-(void)setIsLoaded:(BOOL)isLoaded
{
    _isLoaded = isLoaded;
    
    if (_isLoaded) {
        [self.PickButton setImage:[UIImage imageNamed:@"pickupBotaoAdicionarMusica-on"] forState:UIControlStateNormal];
    }
    else {
        [self.PickButton setImage:[UIImage imageNamed:@"pickupBotaoAdicionarMusica-off"] forState:UIControlStateNormal];
    }
}

- (void)setPathToAudio:(NSString *)pathToAudio
{
    _pathToAudio = pathToAudio;
    
    DWORD flags = 0;
    flags = BASS_SAMPLE_FLOAT|BASS_STREAM_PRESCAN|BASS_STREAM_DECODE;
    
    self.decoder = BASS_StreamCreateFile(kSTREAM_FROM_MEMORY,
                                         [_pathToAudio cStringUsingEncoding:NSUTF8StringEncoding],
                                         kOFFSET_DO_INICIO,
                                         kTAMANHO_DOS_DADOS,
                                         flags);
    
    // The exact length of a stream will be returned once the whole file has been streamed, but until then it is not always possible to 100% accurately estimate the length. The length is always exact for MP3/MP2/MP1 files when the BASS_STREAM_PRESCAN flag is used in the BASS_StreamCreateFile call, otherwise it is an (usually accurate) estimation based on the file size. The length returned for OGG files will usually be exact (assuming the file is not corrupt), but when streaming from the internet (or "buffered" user file), it can be a very rough estimation until the whole file has been downloaded. It will also be an estimate for chained OGG files that are not pre-scanned.
    // AJUSTE: adicionamos 400k a mais no tamanho para o caso de arquivos que não são MP3.
    self.mappedMemorySize = BASS_ChannelGetLength(self.decoder, BASS_POS_BYTE) + kAJUSTE_MEMORIA_ADICIONAL;
    
     NSLog(@"Play back duration is %lld", self.mappedMemorySize);
    
    self.mappedFile = tmpfile();
    int fd = fileno(self.mappedFile);
    ftruncate(fd, self.mappedMemorySize);
    self.mappedMemory = mmap(
                             NULL,                    /* No preferred address. */
                             self.mappedMemorySize,   /* Size of mapped space. */
                             PROT_READ | PROT_WRITE,  /* Read/write access. */
                             MAP_FILE | MAP_SHARED,   /* Map from file (default) and map as shared (see above.) */
                             fd,                      /* The file descriptor. */
                             0                        /* Offset from start of file. */
                             );
    
    [self.scratcher setBuffer:(float *)self.mappedMemory size:self.mappedMemorySize];
    
    info.decoder = self.decoder;
    info.data = self.mappedMemory;
    
    pthread_t thread;
    pthread_create(&thread, NULL, Unpack, (void*)&info);
    
    self.updateTimer = nil;
    self.prevAngle = NAN;
    
    self.isLoaded = YES;
    
    [self tocar:nil];
    
    if ([self.delegate respondsToSelector:@selector(playerIsReady:)]) {
        [self.delegate playerIsReady:self];
        
        [self.volumeSlider setEnabled:YES];
    }
}

#pragma mark -
#pragma mark Designated initializers

- (id)initWithCoder:(NSCoder*)coder
{
    if ((self = [super initWithCoder:coder])) {
        [self setup];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        [self setup];
    }
    return self;
}

#pragma mark -
#pragma mark Metodos publicos

#pragma mark -
#pragma mark Metodos privados

- (void)showMediaPicker
{
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAnyAudio];
    
    [[picker view] setFrame:CGRectMake(0, 0, 320, 480)];
    
    picker.delegate = self;
    picker.allowsPickingMultipleItems = NO;
    picker.prompt = NSLocalizedString (@"AddSongsPrompt", @"Prompt to user to choose some songs to play");
    
    [self presentViewController:picker animated:YES completion:^{
    }];
}

- (void)obtemInformacoes:(MPMediaItemCollection *)collection
{
    if (collection.count == 1) {
        
        NSArray *items = collection.items;
        MPMediaItem *mediaItem =  [items objectAtIndex:0];
        if ([mediaItem isKindOfClass:[MPMediaItem class]]) {
            
            NSString *titulo = [mediaItem valueForProperty:MPMediaItemPropertyTitle];
            NSString *capa = [mediaItem valueForProperty:MPMediaItemPropertyArtwork];
            NSURL *url = [mediaItem valueForProperty:MPMediaItemPropertyAssetURL];
            
            NSLog(@"%@", titulo);
            NSLog(@"%@", capa);
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
    
    NSLog(@"filePath = %@", filePath);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [self setPathToAudio:filePath];
        return;
    }
    else {
        
        myDeleteFile(filePath);
        exportSession.outputURL = [NSURL fileURLWithPath:filePath];
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                NSLog(@"export session completed");
                
                [self setPathToAudio:filePath];
            } else {
                NSLog(@"export session error");
                
                if (exportSession.status == AVAssetExportSessionStatusFailed) {
                    NSLog(@"%@", exportSession.error.localizedDescription);
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
            NSLog (@"Can't delete %@: %@", path, deleteErr);
        }
    }
}

- (void)spinWithOptions:(UIViewAnimationOptions)options {
    // this spin completes 360 degrees every 2 seconds
    [UIView animateWithDuration: 2 //1.65f
                          delay: 0.0f
                        options: options
                     animations: ^{
                         self.imgDeck.transform = CGAffineTransformRotate(self.imgDeck.transform, M_PI / 2);
                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                             if (self.animating) {
                                 // if flag still set, keep spinning with constant speed
                                 [self spinWithOptions: UIViewAnimationOptionCurveLinear];
                             } 
                         }
                     }];
}

- (void) startSpin {
    if (!self.animating) {
        self.animating = YES;
        [self spinWithOptions: UIViewAnimationOptionCurveEaseIn];
    }
}

- (void) stopSpin {
    // set the flag to stop spinning after one last 90 degree increment
    self.animating = NO;
    [self.imgDeck.layer removeAllAnimations];
    
    // Desacelerar
    [UIView animateWithDuration: 0.5
                          delay: 0.0f
                        options: UIViewAnimationOptionCurveEaseOut
                     animations: ^{
                         self.imgDeck.transform = CGAffineTransformRotate(self.imgDeck.transform, M_PI / 4);
                     }
                     completion: ^(BOOL finished) {
                     }];    
}

/*!
 * Anima o brilho do disco LP, dando a impressao de rotacao
 * @param UIView view View para animar
 *
 * @since 1.0.0
 * @author Logics Software
 */
- (void)animaBrilho:(UIView *)view
{
    if (self.isPlaying) {
        CGAffineTransform transformBrilho = view.transform;
        
        UIViewAnimationOptions optionsBrilho = UIViewAnimationOptionCurveEaseInOut;
        
        [UIView animateWithDuration:5.0 delay:0.3 options:optionsBrilho animations:^{
            view.transform = CGAffineTransformRotate(transformBrilho, (M_PI)/12);
        } completion:^(BOOL finished) {
            if (finished && self.isPlaying) {
                [UIView animateWithDuration:5.0 delay:0.3 options:optionsBrilho animations:^{
                    view.transform = CGAffineTransformRotate(transformBrilho, 0);
                } completion:^(BOOL finished) {
                    if (finished && self.isPlaying) [self animaBrilho:view];
                }];
            }
        }];
    }
}

/*!
 * Método para pausar a animação quando a música parar ou estiver realizando o scratch
 * @param CALayer layer Layer da view que deve pausar a animação
 *
 * @since 1.0.0
 * @author Logics Software
 */
-(void)pauseLayer:(CALayer*)layer
{
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
}

/*!
 * Método para continuar a animação quando a música reiniciar ou ao finalizar o scratch
 * @param CALayer layer Layer da view que deve resumir a animação
 *
 * @since 1.0.0
 * @author Logics Software
 */
-(void)resumeLayer:(CALayer*)layer
{
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}

/*!
 * Efetua o setup inicial do VC. Deve ser chamado apenas uma vez.
 * @return void
 *
 * @since 1.0.0
 * @author Logics Software
 */
- (void)setup
{
    // init bass
    BASS_Init(-1, 44100, 0, 0, NULL);
    
    BASS_SetConfig(BASS_CONFIG_BUFFER, 5);
    BASS_SetConfig(BASS_CONFIG_UPDATETHREADS, 1);
    BASS_SetConfig(BASS_CONFIG_UPDATEPERIOD, 5);
    BASS_SetConfig(BASS_CONFIG_IOS_MIXAUDIO, 0);
    
    self.scratcher = [[Scratcher alloc] init];
    self.isPlaying = NO;
    self.isLoaded = NO;

    if (!self.loggerUpdaterTimer) {
        // apenas para evitar que seja chamada multiplas vezes
        self.loggerUpdaterTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                                   target:self
                                                                 selector:@selector(updateTimer:)
                                                                 userInfo:nil
                                                                  repeats:YES];
    }
}

/*!
 * Callback em C que e executado em thread paralela para injetar
 * o som no stream principal
 * @param void* arg Argumentos para serem tratados dentro da thread
 * @return void
 *
 * @since 1.0.0
 * @author Jan Kalis Glow Interactive
 */
void* Unpack(void* arg)
{
    HSTREAM decoder = info.decoder;
    char* output = (char*)info.data;

    // buffer size per step for normalization
    float buf[10000];
    
    BASS_ChannelSetPosition(decoder, 0, BASS_POS_BYTE);
    
    int pos = 0;
    
    while (BASS_ChannelIsActive(decoder))
    {
        DWORD c = BASS_ChannelGetData(decoder, buf, sizeof(buf)|BASS_DATA_FLOAT);
        memcpy(output + pos, buf, c);
        pos += c;
    }
    
    BASS_StreamFree(decoder);
    
    return NULL;
}

/*!
 * Calcula a melhor diferenca entre pontos dado um angulo
 * @param float angule Angulo a ser testado
 * @return float Menor angulo em relacao a origem
 *
 * @since 1.0.0
 * @author Jan Kalis Glow Interactive (Traduzido para Obj-C por Logics Software)
 */
- (float)getBestAngleDiff:(float)angule
{
    float a1 = angule - 2.0f * M_PI;
    float a2 = angule + 2.0f * M_PI;
    
    if (fabsf(angule) < fabsf(a1))
    {
        if (fabsf(angule) < fabsf(a2))
            return angule;
        
        return a2;
    }
    
    if (fabsf(a2) < fabsf(a1))
        return a2;
    
    return a1;
}

/*!
 * Efetua a transformacao visual da view do disco alinhado com o model
 * @param NSTimer timer Timer que chamou o metodo
 * @return void
 *
 * @since 1.0.0
 * @author Jan Kalis Glow Interactive (Traduzido para Obj-C por Logics Software)
 */
- (void)update:(NSTimer*)timer
{
    [self.scratcher update];
	float offset = BYTE_POSITION_TO_PIXELS * [self.scratcher getByteOffset];
	
	CGAffineTransform t = CGAffineTransformIdentity;
    t = CGAffineTransformRotate(t, offset);
	self.vinyl.transform = t;
}

- (void)updateTimer:(NSTimer *)timer
{
    [self.scratcher update];
    QWORD pos = [self.scratcher getByteOffset];
    int time = BASS_ChannelBytes2Seconds(self.channel, pos);
    
    self.loggerTime.text = [NSString stringWithFormat:@"Lido: %llu bytes\nTempo total: %u:%02u CPU: %.2f",
                            pos, time/60, time%60, BASS_GetCPU()];
    self.displayLabel.text = [NSString stringWithFormat:@"%u:%02u", time/60, time%60];
}

#pragma mark -
#pragma mark ViewController life cycle

- (void)viewDidLoad
{
	// init timer
	[self.updateTimer invalidate];
	self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f / 60.0f target:self selector:@selector(update:) userInfo:nil repeats:YES];
    [super viewDidLoad];
    
    [self.volumeSlider setEnabled:NO];
    
    // inicialização do timeOffset para identificar
    // se a animação está sendo executada
    self.imgBrilho.layer.timeOffset = 0.0;

}

#pragma mark -
#pragma mark Storyboards Segues

#pragma mark -
#pragma mark Target/Actions

- (IBAction)setVolume:(UISlider *)sender
{
    if (sender == self.volumeSlider) {
        if (self.scratcher) {
            [self.scratcher setVolume:sender.value];
        }
    }
}

-(IBAction)selecionarMusica:(id)sender
{
    [self showMediaPicker];
}

-(IBAction)tocar:(id)sender
{
    if (self.isLoaded) {
        if (self.isPlaying) {
            
            if ([self.delegate respondsToSelector:@selector(playerWillPause:)]) {
                [self.delegate playerWillPause:self];
            }
            if ([self.delegate respondsToSelector:@selector(pause:)]) {
                [self.delegate pause:self];
                self.isPlaying = NO;
                
                if ([self.delegate respondsToSelector:@selector(playerDidPause:)]) {
                    [self.delegate playerDidPause:self];
                }
            }
        }
        else {
            
            [self setVolume:self.volumeSlider];
            
            if ([self.delegate respondsToSelector:@selector(playerWillPlay:)]) {
                [self.delegate playerWillPlay:self];
            }
            if ([self.delegate respondsToSelector:@selector(play:)]) {
                [self.delegate play:self];
                self.isPlaying = YES;
                [self startSpin];
                
                if ([self.delegate respondsToSelector:@selector(playerDidPlay:)]) {
                    [self.delegate playerDidPlay:self];
                }
            }
        }
    }
    else {
        [self showMediaPicker];
    }
}

-(IBAction)parar:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(playerWillStop:)]) {
        [self.delegate playerWillStop:self];
    }
    if ([self.delegate respondsToSelector:@selector(stop:)]) {
        [self.delegate stop:self];
    
        [self.scratcher stop];
        
        self.isPlaying = NO;
        
        if ([self.delegate respondsToSelector:@selector(playerDidStop:)]) {
            [self.delegate playerDidStop:self];
        }
    }
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

#pragma mark - Touch delegates

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [touches anyObject];
    CGPoint position = [touch locationInView:self.imgDisco];
    
    if (position.x >= 0 && position.y >= 0
        && position.x <= self.imgDisco.frame.size.width
        && position.y <= self.imgDisco.frame.size.height) {

        self.prevAngle = NAN;
        self.initialScratchPosition = [self.scratcher getByteOffset];
        self.angleAccum = 0.0f;
        
        [self.scratcher setByteOffset:(self.initialScratchPosition + self.angleAccum)];
        [self.scratcher beganScratching];
        [self pauseLayer:self.imgBrilho.layer];
        _isPlaying = NO;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.scratcher endedScratching];
    _isPlaying = YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [touches anyObject];
    CGPoint position = [touch locationInView:self.imgDisco];
    
    if (position.x >= 0 && position.y >= 0
        && position.x <= self.imgDisco.frame.size.width
        && position.y <= self.imgDisco.frame.size.height) {
     
        float offsetX = self.vinyl.bounds.size.width/2;
        float offsetY = self.vinyl.bounds.size.height/2;
        
        const float angle = -atan2f(position.x - offsetX, position.y - offsetY);
        
        if (isnan(self.prevAngle))
            self.prevAngle = angle;
        
        const float diff = [self getBestAngleDiff:(angle - self.prevAngle)] / BYTE_POSITION_TO_PIXELS;
        self.angleAccum += diff;
        self.prevAngle = angle;
        
        [self.scratcher setByteOffset:(self.initialScratchPosition + self.angleAccum)];
    }
}

#pragma mark -
#pragma mark Notification center

@end

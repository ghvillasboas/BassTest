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

- (void)free
{
    fclose(self.mappedFile);
	munmap(self.mappedMemory, self.mappedMemorySize);
    
    [self.scratcher freeScratch];
    self.scratcher = nil;
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

- (void)setVolume:(float)volume
{
    _volume = volume;
    
    if (self.scratcher) {
        [self.scratcher setVolume:_volume];
    }
}

- (void)setIsOn:(BOOL)isOn
{
    _isOn = isOn;
    
    if (_isOn) {
        [self.imgLaser setHidden:NO];
        [self startSpin];
    }
    else {
        [self.imgLaser setHidden:YES];
        [self stopSpin];
    }
}

- (void)setIsPlaying:(BOOL)isPlaying
{
    _isPlaying = isPlaying;
    
    if (_isPlaying) {
        // Se o timeOffset for 0.0, inicializa a animação
        if (self.imgBrilho.layer.timeOffset == 0.0) {
            [self animaBrilho:self.imgBrilho];
        }
        // Se for diferente de 0.0, resume
        else {
            [self continuaAnimacaoDoBrilho:self.imgBrilho.layer];
        }
    }
    else {
        [self pausaAnimacaoDoBrilho:self.imgBrilho.layer];
    }
}

-(void)setIsLoaded:(BOOL)isLoaded
{
    _isLoaded = isLoaded;
    
    if (_isLoaded) {
    }
    else {
    }
}

-(void)setArtWork:(UIImage *)artWork
{
    [self.imgDisco setImage:artWork];
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
    
    //Sample Rate
    float sampleRate;
    BASS_ChannelGetAttribute(self.decoder, BASS_ATTRIB_FREQ, &sampleRate);
    self.scratcher.sampleRate = sampleRate;
    
    self.mappedFile = tmpfile();
    int fd = fileno(self.mappedFile);
    ftruncate(fd, self.mappedMemorySize);
    self.mappedMemory = mmap(NULL,                    /* No preferred address. */
                             self.mappedMemorySize,   /* Size of mapped space. */
                             PROT_READ | PROT_WRITE,  /* Read/write access. */
                             MAP_FILE | MAP_SHARED,   /* Map from file (default) and map as shared (see above.) */
                             fd,                      /* The file descriptor. */
                             0);                      /* Offset from start of file. */
    
    [self.scratcher setBuffer:(float *)self.mappedMemory size:self.mappedMemorySize];
    
    info.decoder = self.decoder;
    info.data = self.mappedMemory;
    
    [self.loadingSpin setHidden:NO];
    [self.loadingSpin startAnimating];

    dispatch_queue_t unpackQueue = dispatch_queue_create("FILA UNPACK", NULL);
    dispatch_async(unpackQueue, ^{
        [self Unpack:self.pathToAudio];
    });
    
    self.updateTimer = nil;
    self.prevAngle = NAN;
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

- (void)stop
{
    [self.scratcher stop];
}

#pragma mark -
#pragma mark Metodos privados

- (void)spinWithOptions:(UIViewAnimationOptions)options
{
    [UIView animateWithDuration: 1.8
                          delay: 0.0f
                        options: options
                     animations: ^{
                         self.imgDeck.transform = CGAffineTransformRotate(self.imgDeck.transform, M_PI / 2);
                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                             if (self.animating) {
                                 [self spinWithOptions: UIViewAnimationOptionCurveLinear];
                             } 
                         }
                     }];
}

- (void) startSpin
{
    if (!self.animating) {
        self.animating = YES;
        [self spinWithOptions: UIViewAnimationOptionCurveEaseIn];
    }
}

- (void) stopSpin
{
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
-(void)pausaAnimacaoDoBrilho:(CALayer*)layer
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
-(void)continuaAnimacaoDoBrilho:(CALayer*)layer
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
    self.scratcher = [[Scratcher alloc] init];
    self.isOn = NO;
    self.volume = 0.5;
    self.isPlaying = NO;
    self.isLoaded = NO;
    self.animating = NO;
    
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
- (void)Unpack:(NSString*)path
{
    char* output = (char*)self.mappedMemory;
    NSString *p = [NSString stringWithString:path];
    
    // buffer size per step for normalization
    float buf[10000];
    
    BASS_ChannelSetPosition(self.decoder, 0, BASS_POS_BYTE);
    
    int pos = 0;
    float atual = 0;
    float total = 0;
    BOOL liberado = NO;
    
    while (BASS_ChannelIsActive(self.decoder))
    {
        DWORD c = BASS_ChannelGetData(self.decoder, buf, sizeof(buf)|BASS_DATA_FLOAT);
        memcpy(output + pos, buf, c);
        pos += c;
        
        atual = pos;
        total = (float)self.mappedMemorySize;
        
        if (!liberado && (atual/total) > 0.2) {
            
            liberado = YES;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.loadingSpin setHidden:YES];
                [self.loadingSpin stopAnimating];
                
                self.isLoaded = YES;
                
                if ([self.delegate respondsToSelector:@selector(playerIsReady:)]) {
                    [self.delegate playerIsReady:self];
                }
            });
        }
        if (!self.view.window) {
            break;
        }
    }
    
    BASS_StreamFree(self.decoder);
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
	self.imgDisco.transform = t;
}

- (void)updateTimer:(NSTimer *)timer
{
//    [self.scratcher update];
//    QWORD pos = [self.scratcher getByteOffset];
//    int time = BASS_ChannelBytes2Seconds(self.channel, pos);
//    
//    self.loggerTime.text = [NSString stringWithFormat:@"Lido: %llu bytes\nTempo total: %u:%02u CPU: %.2f",
//                            pos, time/60, time%60, BASS_GetCPU()];
//    self.displayLabel.text = [NSString stringWithFormat:@"%u:%02u", time/60, time%60];
}

#pragma mark -
#pragma mark ViewController life cycle

- (void)viewDidLoad
{
	// init timer
	[self.updateTimer invalidate];
	self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f / 30.0f target:self selector:@selector(update:) userInfo:nil repeats:YES];
    [super viewDidLoad];
    
    [self.loadingSpin stopAnimating];
    [self.loadingSpin setHidden:YES];
    
    // inicialização do timeOffset para identificar
    // se a animação está sendo executada
    self.imgBrilho.layer.timeOffset = 0.0;
}

#pragma mark -
#pragma mark Storyboards Segues

#pragma mark -
#pragma mark Target/Actions

#pragma mark -
#pragma mark Delegates

#pragma mark - Touch delegates


- (BOOL)circuloContemPonto:(CGPoint)ponto noCentro:(CGPoint)centro comRaio:(float)raio
{
    return powf((ponto.x - centro.x), 2) + powf((ponto.y - centro.y), 2) <= powf(raio, 2);    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [touches anyObject];
    CGPoint position = [touch locationInView:self.view];
    
    if ([self circuloContemPonto:position noCentro:self.imgDisco.center comRaio:self.imgDisco.bounds.size.width/2]) {

        self.prevAngle = NAN;
        self.initialScratchPosition = [self.scratcher getByteOffset];
        self.angleAccum = 0.0f;
        
        [self.scratcher setByteOffset:(self.initialScratchPosition + self.angleAccum)];
        [self.scratcher beganScratching];
        [self pausaAnimacaoDoBrilho:self.imgBrilho.layer];
        _isPlaying = NO;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.scratcher endedScratching];
    [self continuaAnimacaoDoBrilho:self.imgBrilho.layer];
    _isPlaying = YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [touches anyObject];
    CGPoint position = [touch locationInView:self.view];
    
    if ([self circuloContemPonto:position noCentro:self.imgDisco.center comRaio:self.imgDisco.bounds.size.width/2]) {
    
        float offsetX = self.imgDisco.center.x;
        float offsetY = self.imgDisco.center.y;
        
        const float angle = -atan2f(position.x - offsetX, position.y - offsetY);
        
        if (isnan(self.prevAngle))
            self.prevAngle = angle;
        
        const float diff = [self getBestAngleDiff:(angle - self.prevAngle)] / BYTE_POSITION_TO_PIXELS;
        self.angleAccum += diff;
        self.prevAngle = angle;
        
        // @bugifx
        // Previne que o disco seja girado em sentido anti-horario alem do inicio da musica
        float offsetByte = (self.initialScratchPosition + self.angleAccum) < 0 ? self.initialScratchPosition : (self.initialScratchPosition + self.angleAccum);
        [self.scratcher setByteOffset:offsetByte];
    }
}

#pragma mark -
#pragma mark Notification center

@end

//
//  AudioScratchDemoViewController.mm
//  AudioScratchDemo
//
//  Created by Jan Kalis on 10/22/10.
//  Copyright 2010 Jan Kalis Glow Interactive. All rights reserved.
//
#import "ScratcherViewController.h"
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
@property int mappedMemorySize;
@property double firstGetSeconds;
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

#pragma mark -
#pragma mark Setters overriders

- (void)setMp3:(NSString *)mp3
{
    _mp3 = mp3;
    
    self.decoder = BASS_StreamCreateFile(FALSE, [_mp3 cStringUsingEncoding:NSUTF8StringEncoding], 0, 0, BASS_SAMPLE_FLOAT|BASS_STREAM_PRESCAN|BASS_STREAM_DECODE);
    
    self.mappedMemorySize = BASS_ChannelGetLength(self.decoder, BASS_POS_BYTE);
    
    self.mappedFile = tmpfile();
    int fd = fileno(self.mappedFile);
    
    ftruncate(fd, self.mappedMemorySize);
    
    self.mappedMemory = mmap(
                             NULL,                    /* No preferred address. */
                             self.mappedMemorySize,                /* Size of mapped space. */
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
    
    self.scratcher = [[Scratcher alloc] init];
    self.tocando = NO;
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
	const double now = [self.scratcher getSeconds];
	static double lastTime = NAN;
	if (isnan(lastTime)) lastTime = now;
	lastTime = now;
	
    [self.scratcher update];
	float offset = BYTE_POSITION_TO_PIXELS * [self.scratcher getByteOffset];
	
	CGAffineTransform t = CGAffineTransformIdentity;
	
    //	t = CGAffineTransformTranslate(t, -160.0f, -160.0f);
    //	t = CGAffineTransformTranslate(t, 160.0f, 160.0f);
	t = CGAffineTransformRotate(t, offset);
	
	self.vinyl.transform = t;
}


#pragma mark -
#pragma mark ViewController life cycle

- (void)viewDidLoad
{
	// init timer
	[self.updateTimer invalidate];
	self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f / 60.0f target:self selector:@selector(update:) userInfo:nil repeats:YES];
    
    [super viewDidLoad];
}

#pragma mark -
#pragma mark Storyboards Segues

#pragma mark -
#pragma mark Target/Actions

- (IBAction)setVolume:(UISlider *)sender
{
    if (sender == self.volumeSlider) {
        [self.scratcher setVolume:sender.value];
    }
}

-(IBAction)play:(id)sender
{
    if (self.tocando) {
        if ([self.delegate respondsToSelector:@selector(pausarScratcher:)]) {
            [self.delegate pausarScratcher:self];
            [self.PlayButton setTitle:@"Resumir" forState:UIControlStateNormal];
        }
    }
    else {
        
        [self setVolume:self.volumeSlider];
        
        if ([self.delegate respondsToSelector:@selector(tocarScratcher:)]) {
            [self.delegate tocarScratcher:self];
            [self.PlayButton setTitle:@"Pause" forState:UIControlStateNormal];
        }
    }
    
    self.tocando = !self.tocando;
}

-(IBAction)stop:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(pararScratcher:)]) {
        [self.delegate pararScratcher:self];
        [self.PlayButton setTitle:@"Play" forState:UIControlStateNormal];
        self.tocando = NO;
    }
}

#pragma mark -
#pragma mark Delegates

#pragma mark - Touch delegates

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.prevAngle = NAN;
	self.initialScratchPosition = [self.scratcher getByteOffset];
	self.angleAccum = 0.0f;
	
    [self.scratcher setByteOffset:(self.initialScratchPosition + self.angleAccum)];
    [self.scratcher beganScratching];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.scratcher endedScratching];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch* touch = [touches anyObject];
	CGPoint position = [touch locationInView:self.view];
	
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

#pragma mark -
#pragma mark Notification center

@end

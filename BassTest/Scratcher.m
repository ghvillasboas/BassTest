//
//  Scratcher.m
//  AudioScratchDemo
//
//  Created by George Henrique Villasboas on 22/03/13.
//
//

#import "Scratcher.h"
#import <assert.h>
#import <math.h>
#import <sys/time.h>
#import <time.h>

#define BASE_PLAYBACK_FREQUENCY 44100.0f
#define AUDIO_SAMPLE_SIZE (sizeof(float) * 2)

@interface Scratcher()
static DWORD CALLBACK WriteScratchStream(HSTREAM handle, void* writeBuffer, DWORD length, void* user);
@end

@implementation Scratcher

#pragma mark -
#pragma mark Getters overriders

#pragma mark -
#pragma mark Setters overriders

#pragma mark -
#pragma mark Designated initializers

- (id)init
{
    self = [super init];
    if (self) {
        
        self.firstGetSeconds = -1.0;
        
        self.isScratching = false;
        self.scratchingPositionVelocity = BASE_PLAYBACK_FREQUENCY;
        self.scratchingPositionSmoothedVelocity = BASE_PLAYBACK_FREQUENCY;
        
        self.smoothBufferPosition = 0;
        for (unsigned int i = 0; i < smoothBufferSize; ++i)
            self.smoothBuffer[i] = (float)BASE_PLAYBACK_FREQUENCY / smoothBufferSize;
        
        self.buffer = NULL;
        
        // init stream that will be played when scratching
        self.soundTrackScratchStreamHandle = BASS_StreamCreate(BASE_PLAYBACK_FREQUENCY, 2, BASS_SAMPLE_FLOAT, &WriteScratchStream, (__bridge void *)(self));
        
        // play scratch stream
        BASS_ChannelPlay(self.soundTrackScratchStreamHandle, false);
    }
    
    return self;
}

#pragma mark -
#pragma mark Metodos publicos

/*!
 * Buffer suavizado
 * @return float* Ponteiro para o buffer suavizado
 *
 * @since 1.0.0
 * @author Jan Kalis Glow Interactive (Traduzido para Obj-C por Logics Software)
 */
- (float *)smoothBuffer
{
    return smoothBuffer;
}

/*!
 * Acoes de inicializacao interna do scratch
 * Deve ser chamada ao iniciar o scratch
 * @return void
 *
 * @since 1.0.0
 * @author Jan Kalis Glow Interactive (Traduzido para Obj-C por Logics Software)
 */
- (void)beganScratching
{
	self.previousPositionOffset = NAN;
	self.isScratching = true;
}

/*!
 * Acoes de finalizacao interna do scratch
 * Deve ser chamada ao finalizar o scratch
 * @return void
 *
 * @since 1.0.0
 * @author Jan Kalis Glow Interactive (Traduzido para Obj-C por Logics Software)
 */
- (void)endedScratching
{
	self.scratchingPositionVelocity = BASE_PLAYBACK_FREQUENCY;
	self.isScratching = false;
}

/*!
 * Seta a posicao byte no audio quando fazendo o scratch
 * @param float buffer Posicao no buffer
 * @param int size Tamanho do buffer
 * @return void
 *
 * @since 1.0.0
 * @author Jan Kalis Glow Interactive (Traduzido para Obj-C por Logics Software)
 */
- (void)setBuffer:(float *)buffer size:(int)size
{
	self.buffer = buffer;
	self.size = size / (2 * sizeof(float));
}

/////////////////////////////////////////////////////////////////////////////////////////////
/// @brief Sets byte position in the audio track when scratching
///
/////////////////////////////////////////////////////////////////////////////////////////////

/*!
 * Seta o offset da posicao byte no audio quando fazendo o scratch
 * @param float byteOffset Posicao no buffer
 * @return void
 *
 * @since 1.0.0
 * @author Jan Kalis Glow Interactive (Traduzido para Obj-C por Logics Software)
 */
- (void)setByteOffset:(float)byteOffset
{
	self.positionOffset = byteOffset / AUDIO_SAMPLE_SIZE;
}

/*!
 * Pega a posicao no stream do scratch
 * @return float Offset do byte no stream do scratch
 *
 * @since 1.0.0
 * @author Jan Kalis Glow Interactive (Traduzido para Obj-C por Logics Software)
 */
- (float)getByteOffset
{
	return self.scratchingPositionOffset * AUDIO_SAMPLE_SIZE;
}

/*!
 * Pega os segundos de um dado intervalo
 * @return double Segundos de um dado intervalo
 *
 * @since 1.0.0
 * @author Jan Kalis Glow Interactive (Traduzido para Obj-C por Logics Software)
 */
- (double)getSeconds
{
    srandom(time(NULL));
    
    struct timeval now;
    gettimeofday(&now, NULL);
    
    
    double time = now.tv_sec + now.tv_usec / 1000000.0;
    
    if (self.firstGetSeconds < 0.0) self.firstGetSeconds = time;
    
    return time - self.firstGetSeconds;
}

/*!
 * Atualiza o velocidade atual do scratch
 * @return void
 *
 * @since 1.0.0
 * @author Jan Kalis Glow Interactive (Traduzido para Obj-C por Logics Software)
 */
- (void)update
{
	float time = [self getSeconds];
    
	if (self.isScratching == false)
	{
		self.scratchingPositionVelocity = BASE_PLAYBACK_FREQUENCY;
	}
	else
	{
		
		if (isnan(self.previousPositionOffset))
		{
			self.scratchingPositionVelocity = 0.0f;
		}
		else
		{
			// calculate position speed (= dPosition / dTime)
			self.scratchingPositionVelocity = (self.positionOffset - self.previousPositionOffset) / (time - self.previousTime);
            
			if (isnan(self.scratchingPositionVelocity) || isinf(self.scratchingPositionVelocity)) self.scratchingPositionVelocity = 0.0f;
		}
        
		self.previousPositionOffset = self.positionOffset;
	}
	
	self.previousTime = time;
}

#pragma mark -
#pragma mark Metodos privados

/*!
 * "6-point, 5th-order optimal 32x z-form implementation" interpolator
 * Detalhes do calculo em: http://www.student.oulu.fi/~oniemita/dsp/deip.pdf
 * @param float x
 * @param float y Array de floats
 * @return float Onda interpolada
 *
 * @since 1.0.0
 * @author Olli Niemitalo
 */
static float wave_interpolator(float x, float y[6])
{
	const int offset = 2;
	
	float z = x - 1/2.0;
	float even1 = y[offset+1]+y[offset+0], odd1 = y[offset+1]-y[offset+0];
	float even2 = y[offset+2]+y[offset+-1], odd2 = y[offset+2]-y[offset+-1];
	float even3 = y[offset+3]+y[offset+-2], odd3 = y[offset+3]-y[offset+-2];
	
	float c0 = even1*0.42685983409379380 + even2*0.07238123511170030
	+ even3*0.00075893079450573;
	float c1 = odd1*0.35831772348893259 + odd2*0.20451644554758297
	+ odd3*0.00562658797241955;
	float c2 = even1*-0.217009177221292431 + even2*0.20051376594086157
	+ even3*0.01649541128040211;
	float c3 = odd1*-0.25112715343740988 + odd2*0.04223025992200458
	+ odd3*0.02488727472995134;
	float c4 = even1*0.04166946673533273 + even2*-0.06250420114356986
	+ even3*0.02083473440841799;
	float c5 = odd1*0.08349799235675044 + odd2*-0.04174912841630993
	+ odd3*0.00834987866042734;
	
	return ((((c5*z+c4)*z+c3)*z+c2)*z+c1)*z+c0;
}

/*!
 * Funcao em C que efetua a escrita do scratch no stream
 * @return void Callback
 *
 * @since 1.0.0
 * @author Jan Kalis Glow Interactive
 */
DWORD CALLBACK WriteScratchStream(HSTREAM handle, void* writeBuffer, DWORD length, void* user)
{
	Scratcher *soundTrackScratcher = (__bridge Scratcher *)user;
    
	
	if (soundTrackScratcher.buffer == NULL)
		return 0;
	
	float* dest = (float*)writeBuffer;
	
	const int numSamplesToWrite = length / AUDIO_SAMPLE_SIZE;
	
	// aux vars for interpolation
	float leftInterpData[6], rightInterpData[6];
	
	// source samples
    const float* const samples = soundTrackScratcher.buffer;
	
	for (int i = 0; i < numSamplesToWrite; ++i){
        /* algorithm:
         
         1. Smooth out input position speed using moving averages (length of the average is smoothBufferSize, but is smaller when scratching started).
         This can lead to drifting, i.e. the position of the finger gets out of sync with the position in the scratch stream. It is caused by
         not using the *exact* position speed, but its smoothed version.
         
         2.	To fix drifting, we "push" the velocity vector in the direction towards the correct position
         */
        
		// find moving average
		soundTrackScratcher.scratchingPositionSmoothedVelocity -= soundTrackScratcher.smoothBuffer[soundTrackScratcher.smoothBufferPosition];
		soundTrackScratcher.smoothBuffer[soundTrackScratcher.smoothBufferPosition] = soundTrackScratcher.scratchingPositionVelocity / smoothBufferSize;
		soundTrackScratcher.scratchingPositionSmoothedVelocity += soundTrackScratcher.smoothBuffer[soundTrackScratcher.smoothBufferPosition];
		
		soundTrackScratcher.smoothBufferPosition = (++soundTrackScratcher.smoothBufferPosition) % smoothBufferSize;
		
		float velocity = soundTrackScratcher.scratchingPositionSmoothedVelocity;
		
		
		if (soundTrackScratcher.isScratching)
		{
			// modify velocity to point to the correct position
			const float targetOffset = soundTrackScratcher.positionOffset;
			const float offsetDiff = targetOffset - soundTrackScratcher.scratchingPositionOffset;
			velocity += offsetDiff * 10.0f;
		}
		
		// update scratch buffer position
		soundTrackScratcher.scratchingPositionOffset += velocity / BASE_PLAYBACK_FREQUENCY;
        
		// clamp position to song
		soundTrackScratcher.scratchingPositionOffset = fmodf(soundTrackScratcher.scratchingPositionOffset, soundTrackScratcher.size);
		if (soundTrackScratcher.scratchingPositionOffset < 0.0f)
			soundTrackScratcher.scratchingPositionOffset += soundTrackScratcher.size;
        
        // find absolute scratch buffer position
		const float fBufferPosition = soundTrackScratcher.scratchingPositionOffset;
		
		// use interpolation to find a sample value
		int	iBufferPosition = (int)fBufferPosition;
		float rem = fBufferPosition - iBufferPosition;
		
		if (iBufferPosition < 2)
			iBufferPosition = 2;
		if (iBufferPosition > soundTrackScratcher.size - 4)
			iBufferPosition = soundTrackScratcher.size - 4;
		
		const float* sample = &samples[2 * (iBufferPosition - 2)];
        
        leftInterpData[0] = *sample;
        ++sample;
        rightInterpData[0] = *sample;
        ++sample;
        leftInterpData[1] = *sample;
        ++sample;
        rightInterpData[1] = *sample;
        ++sample;
        leftInterpData[2] = *sample;
        ++sample;
        rightInterpData[2] = *sample;
        ++sample;
        leftInterpData[3] = *sample;
        ++sample;
        rightInterpData[3] = *sample;
        ++sample;
        leftInterpData[4] = *sample;
        ++sample;
        rightInterpData[4] = *sample;
        ++sample;
        leftInterpData[5] = *sample;
        ++sample;
        rightInterpData[5] = *sample;
        ++sample;
		
        *dest = wave_interpolator(rem, leftInterpData);
		++dest;
        *dest = wave_interpolator(rem, rightInterpData);
		++dest;
	}
    
	return length;
}

#pragma mark -
#pragma mark Notification center

@end

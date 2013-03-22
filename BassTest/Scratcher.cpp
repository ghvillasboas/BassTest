/*
 *  Scratcher.cpp
 *  RadballsPP
 *
 *  Created by Jan Kalis on 5/14/10.
 *  Copyright 2010 Glow Interactive. All rights reserved.
 *
 */

#import <assert.h>
#import <math.h>
#import "Scratcher.h"
#import "Sys.h"

#define BASE_PLAYBACK_FREQUENCY 44100.0f
#define AUDIO_SAMPLE_SIZE (sizeof(float) * 2)

/////////////////////////////////////////////////////////////////////////////////////////////
/// @brief
/// 
/////////////////////////////////////////////////////////////////////////////////////////////
Scratcher::Scratcher()
{
	isScratching_ = false;
	scratchingPositionVelocity_ = BASE_PLAYBACK_FREQUENCY;
	scratchingPositionSmoothedVelocity_ = BASE_PLAYBACK_FREQUENCY;
	
	smoothBufferPosition_ = 0;
	for (unsigned int i = 0; i < smoothBufferSize; ++i)
		smoothBuffer_[i] = (float)BASE_PLAYBACK_FREQUENCY / smoothBufferSize;
	
	buffer_ = NULL;
	
	// init stream that will be played when scratching
	soundTrackScratchStreamHandle_ = BASS_StreamCreate(BASE_PLAYBACK_FREQUENCY, 2, BASS_SAMPLE_FLOAT, Scratcher::WriteScratchStream, this);

	// play scratch stream
	BASS_ChannelPlay(soundTrackScratchStreamHandle_, false);
}

void Scratcher::stopMusic()
{
    BASS_ChannelStop(soundTrackScratchStreamHandle_);
}

void Scratcher::playMusic()
{
    BASS_ChannelPlay(soundTrackScratchStreamHandle_, false);
}

void Scratcher::pauseMusic()
{
    BASS_ChannelPause(soundTrackScratchStreamHandle_);
}

/////////////////////////////////////////////////////////////////////////////////////////////
/// @brief
/// 
/////////////////////////////////////////////////////////////////////////////////////////////
Scratcher::~Scratcher()
{
}

/////////////////////////////////////////////////////////////////////////////////////////////
/// @brief Sets byte position in the audio track when scratching
/// 
/////////////////////////////////////////////////////////////////////////////////////////////
void Scratcher::BeganScratching()
{
	previousPositionOffset_ = NAN;
	isScratching_ = true;
}

/////////////////////////////////////////////////////////////////////////////////////////////
/// @brief Sets byte position in the audio track when scratching
/// 
/////////////////////////////////////////////////////////////////////////////////////////////
void Scratcher::EndedScratching()
{
	scratchingPositionVelocity_ = BASE_PLAYBACK_FREQUENCY;
	isScratching_ = false;
}

/////////////////////////////////////////////////////////////////////////////////////////////
/// @brief Sets byte position in the audio track when scratching
/// 
/////////////////////////////////////////////////////////////////////////////////////////////
void Scratcher::SetBuffer(float* buffer, int size)
{
	buffer_ = buffer;
	size_ = size / (2 * sizeof(float));
	
}

/////////////////////////////////////////////////////////////////////////////////////////////
/// @brief Sets byte position in the audio track when scratching
/// 
/////////////////////////////////////////////////////////////////////////////////////////////
void Scratcher::SetByteOffset(float byteOffset)
{
	positionOffset_ = byteOffset / AUDIO_SAMPLE_SIZE;
}

/////////////////////////////////////////////////////////////////////////////////////////////
/// @brief Gets byte position in the scratch stream
/// @return Byte offset in the scratch stream
/////////////////////////////////////////////////////////////////////////////////////////////
float Scratcher::GetByteOffset() const
{
	return scratchingPositionOffset_ * AUDIO_SAMPLE_SIZE;
}

/////////////////////////////////////////////////////////////////////////////////////////////
/// @brief Updates current scratch velocity
/// 
/////////////////////////////////////////////////////////////////////////////////////////////
void Scratcher::Update(float dt)
{
	float time = Sys::GetSeconds();

	if (isScratching_ == false)
	{
		scratchingPositionVelocity_ = BASE_PLAYBACK_FREQUENCY;
	}
	else
	{
		
		if (isnan(previousPositionOffset_))
		{
			scratchingPositionVelocity_ = 0.0f;
		}
		else	
		{
			// calculate position speed (= dPosition / dTime)
			scratchingPositionVelocity_ = (positionOffset_ - previousPositionOffset_) / (time - previousTime_);

			if (isnan(scratchingPositionVelocity_) || isinf(scratchingPositionVelocity_)) scratchingPositionVelocity_ = 0.0f;
		}

		previousPositionOffset_ = positionOffset_;
	}
	
	previousTime_ = time;
}

/////////////////////////////////////////////////////////////////////////////////////////////
/// @brief	"6-point, 5th-order optimal 32x z-form implementation" interpolator, see
///			Olli Niemitalo's "Elephant" paper
///			http://www.student.oulu.fi/~oniemita/dsp/deip.pdf
///
///			It may be interesting to see if other interpolation function yields different results.
/////////////////////////////////////////////////////////////////////////////////////////////
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

/////////////////////////////////////////////////////////////////////////////////////////////
/// @brief Writes into the scratching stream.
/// 
/////////////////////////////////////////////////////////////////////////////////////////////
DWORD CALLBACK Scratcher::WriteScratchStream(HSTREAM handle, void* writeBuffer, DWORD length, void* user)
{
	Scratcher* soundTrackScratcher = static_cast<Scratcher*>(user);

	
	if (soundTrackScratcher->buffer_ == NULL)
		return 0;
	
	float* dest = (float*)writeBuffer;
	
	const int numSamplesToWrite = length / AUDIO_SAMPLE_SIZE;
	
	// aux vars for interpolation
	float leftInterpData[6], rightInterpData[6];
	
	// source samples
	const float* const samples = soundTrackScratcher->buffer_;
	float* smoothBuffer = soundTrackScratcher->smoothBuffer_;
	float& scratchingPositionSmoothedVelocity = soundTrackScratcher->scratchingPositionSmoothedVelocity_;
	int& smoothBufferPosition = soundTrackScratcher->smoothBufferPosition_;
	const bool isScratching = soundTrackScratcher->isScratching_;
	float& scratchingPositionOffset = soundTrackScratcher->scratchingPositionOffset_;
	const float positionOffset = soundTrackScratcher->positionOffset_;
	const float scratchingPositionVelocity = soundTrackScratcher->scratchingPositionVelocity_;
	const int size = soundTrackScratcher->size_;
	
	for (int i = 0; i < numSamplesToWrite; ++i)
	{
/* algorithm:

 1. Smooth out input position speed using moving averages (length of the average is smoothBufferSize, but is smaller when scratching started).
	This can lead to drifting, i.e. the position of the finger gets out of sync with the position in the scratch stream. It is caused by
	not using the *exact* position speed, but its smoothed version.
 
 2.	To fix drifting, we "push" the velocity vector in the direction towards the correct position
*/

		// find moving average
		scratchingPositionSmoothedVelocity -= smoothBuffer[smoothBufferPosition];
		smoothBuffer[smoothBufferPosition] = scratchingPositionVelocity / smoothBufferSize;
		scratchingPositionSmoothedVelocity += smoothBuffer[smoothBufferPosition];
		
		smoothBufferPosition = (++smoothBufferPosition) % smoothBufferSize;
		
		float velocity = scratchingPositionSmoothedVelocity;
		
		
		if (isScratching)
		{
			// modify velocity to point to the correct position
			const float targetOffset = positionOffset;
			const float offsetDiff = targetOffset - scratchingPositionOffset;
			velocity += offsetDiff * 10.0f;
		}
		
		// update scratch buffer position
		scratchingPositionOffset += velocity / BASE_PLAYBACK_FREQUENCY;

		// clamp position to song
		scratchingPositionOffset = fmodf(scratchingPositionOffset, size);
		if (scratchingPositionOffset < 0.0f)
			scratchingPositionOffset += size;
        
        // find absolute scratch buffer position
		const float fBufferPosition = scratchingPositionOffset;
		
		// use interpolation to find a sample value
		int	iBufferPosition = (int)fBufferPosition;
		float rem = fBufferPosition - iBufferPosition;
		
		if (iBufferPosition < 2) 
			iBufferPosition = 2;
		if (iBufferPosition > size - 4)
			iBufferPosition = size - 4;
		
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



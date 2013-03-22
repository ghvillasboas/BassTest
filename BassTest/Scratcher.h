/*
 *  Scratcher.h
 *  RadballsPP
 *
 *  Created by Jan Kalis on 5/14/10.
 *  Copyright 2010 Glow Interactive. All rights reserved.
 *
 */

#import "bass.h"

static const unsigned int smoothBufferSize = 3000;

class Scratcher
{
	
public:
	Scratcher();
	~Scratcher();

	void Update(float dt);

	void SetBuffer(float* buffer, int size);
	
	void SetByteOffset(float byteOffset);
	float GetByteOffset() const;
	
	void BeganScratching();
	void EndedScratching();
    
    void stopMusic();
    void playMusic();
    void pauseMusic();
    void recordMusic();
	
private:
	static DWORD CALLBACK WriteScratchStream(HSTREAM handle, void* writeBuffer, DWORD length, void* user);
	
	HSTREAM soundTrackScratchStreamHandle_;
	
	bool isScratching_;
	
	float* buffer_;
	int size_;
	
	float scratchingPositionOffset_;

	float scratchingPositionSmoothedVelocity_;
	float scratchingPositionVelocity_;

	float smoothBuffer_[smoothBufferSize];
	int smoothBufferPosition_;

	float previousTime_;

	float positionOffset_;
	float previousPositionOffset_;
};

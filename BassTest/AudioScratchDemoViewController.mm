//
//  AudioScratchDemoViewController.mm
//  AudioScratchDemo
//
//  Created by Jan Kalis on 10/22/10.
//  Copyright 2010 Glow Interactive. All rights reserved.
//

#import <sys/stat.h>
#import <sys/mman.h>
#import <fcntl.h>
#import <pthread.h>

#import <QuartzCore/CALayer.h>

#import "AudioScratchDemoViewController.h"

#import "Scratcher.h"
#import "Sys.h"

#define BYTE_POSITION_TO_PIXELS 0.00001f
#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

namespace
{
	struct Info
	{
		HSTREAM decoder;
		void* data;
	} info;
	
	float GetBestAngleDiff(float a)
	{
		float a1 = a - 2.0f * M_PI;
		float a2 = a + 2.0f * M_PI;
		
		if (fabsf(a) < fabsf(a1))
		{
			if (fabsf(a) < fabsf(a2))
				return a;
			
			return a2;
		}
		
		if (fabsf(a2) < fabsf(a1))
			return a2;
		
		return a1;
	}

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
}

@implementation AudioScratchDemoViewController


/////////////////////////////////////////////////////////////////////////////////////////////
/// @brief Initialize Bass sound system and load audio.
/// 
/////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithCoder:(NSCoder*)coder
{
    if ((self = [super initWithCoder:coder])) 
	{
		Sys::Init();
		
		// init bar
		UIImage* vinylImage = [UIImage imageNamed:@"vinyl"];
		vinyl_ = [[UIImageView alloc] initWithImage:vinylImage];

		// init bass
		BASS_Init(-1, 44100, 0, 0, NULL);
		
		BASS_SetConfig(BASS_CONFIG_BUFFER, 5);
		BASS_SetConfig(BASS_CONFIG_UPDATETHREADS, 1);
		BASS_SetConfig(BASS_CONFIG_UPDATEPERIOD, 5);	
		
		scratcher_ = new Scratcher();
        
        //printf(Sys::GetAbsolutePath("#audio2.mp3").c_str());
        
		decoder_ = BASS_StreamCreateFile(FALSE, Sys::GetAbsolutePath("#audio2.mp3").c_str(), 0, 0, BASS_SAMPLE_FLOAT|BASS_STREAM_PRESCAN|BASS_STREAM_DECODE);
        
		mappedMemorySize_ = BASS_ChannelGetLength(decoder_, BASS_POS_BYTE);
		
		mappedFile_ = tmpfile();
		int fd = fileno(mappedFile_);
		
		ftruncate(fd, mappedMemorySize_);
		
		mappedMemory_ = mmap(
							NULL,                    /* No preferred address. */
							mappedMemorySize_,       /* Size of mapped space. */
							PROT_READ | PROT_WRITE,  /* Read/write access. */
							MAP_FILE | MAP_SHARED,   /* Map from file (default) and map as shared (see above.) */
							fd,                      /* The file descriptor. */
							0                        /* Offset from start of file. */
							);
		
		
		
		
		scratcher_->SetBuffer((float*)mappedMemory_, mappedMemorySize_);
		
		
		info.decoder = decoder_;
		info.data = mappedMemory_;
		
		pthread_t thread;
		pthread_create(&thread, NULL, Unpack, (void*)&info);
		
		updateTimer_ = nil;
		prevAngle_ = NAN;
    }
    return self;
}

/////////////////////////////////////////////////////////////////////////////////////////////
/// @brief Timer tick update function. 
/// @param timer - 
/////////////////////////////////////////////////////////////////////////////////////////////
- (void)update:(NSTimer*)timer
{
	const double now = Sys::GetSeconds();
	static double lastTime = NAN;
	if (isnan(lastTime)) lastTime = now;
	const double dt = now - lastTime;
	lastTime = now;
	
	scratcher_->Update(dt);
	float offset = BYTE_POSITION_TO_PIXELS * scratcher_->GetByteOffset();
	
	CGAffineTransform t = CGAffineTransformIdentity;
	
	t = CGAffineTransformTranslate(t, -256.0f, -256.0f);
	t = CGAffineTransformTranslate(t, 160.0f, 240.0f);
	t = CGAffineTransformRotate(t, offset);
	
	vinyl_.transform = t;
}

/////////////////////////////////////////////////////////////////////////////////////////////
/// @brief Called when view unpacked from xib and loaded
/// 
/////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad 
{
	[self.view addSubview:vinyl_];

	// init timer
	[updateTimer_ invalidate];
	updateTimer_ = [NSTimer scheduledTimerWithTimeInterval:1.0f / 60.0f target:self selector:@selector(update:) userInfo:nil repeats:YES];
    
    [super viewDidLoad];
}

- (IBAction)facaAlgumaCoisa:(UIButton *)sender
{
    if (sender.tag == 1) {
        scratcher_->playMusic();
    }
    else if (sender.tag == 2) {
        scratcher_->pauseMusic();
    }
    else if (sender.tag == 3) {
        scratcher_->stopMusic();
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////
///
/// 
/////////////////////////////////////////////////////////////////////////////////////////////
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	prevAngle_ = NAN;
	initialScratchPosition_ = scratcher_->GetByteOffset();
	angleAccum_ = 0.0f;
	
	scratcher_->SetByteOffset(initialScratchPosition_ + angleAccum_);
	scratcher_->BeganScratching();
}

/////////////////////////////////////////////////////////////////////////////////////////////
///
/// 
/////////////////////////////////////////////////////////////////////////////////////////////
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	scratcher_->EndedScratching();
}

/////////////////////////////////////////////////////////////////////////////////////////////
///
/// 
/////////////////////////////////////////////////////////////////////////////////////////////
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch* touch = [touches anyObject];
	CGPoint position = [touch locationInView:self.view];
	
	const float angle = -atan2f(position.x - 160.0f, position.y - 240.0f);
	
	if (isnan(prevAngle_))
		prevAngle_ = angle;
	
	const float diff = GetBestAngleDiff(angle - prevAngle_) / BYTE_POSITION_TO_PIXELS;
	angleAccum_ += diff;
	prevAngle_ = angle;

	scratcher_->SetByteOffset(initialScratchPosition_ + angleAccum_);
}

/////////////////////////////////////////////////////////////////////////////////////////////
/// 
/// 
/////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc 
{
	fclose(mappedFile_);
	munmap(mappedMemory_, mappedMemorySize_);

	delete scratcher_;
}

@end

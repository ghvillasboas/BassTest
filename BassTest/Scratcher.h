//
//  Scratcher.h
//  AudioScratchDemo
//
//  Created by George Henrique Villasboas on 22/03/13.
//
//

#import <Foundation/Foundation.h>
#import "bass.h"

#define smoothBufferSize 3000

@interface Scratcher : NSObject
{
    float smoothBuffer[3000];
}

@property HSTREAM soundTrackScratchStreamHandle;
@property bool isScratching;
@property float* buffer;
@property int size;
@property float scratchingPositionOffset;
@property float scratchingPositionSmoothedVelocity;
@property float scratchingPositionVelocity;
@property (readonly) float *smoothBuffer;
@property int smoothBufferPosition;
@property float previousTime;
@property float positionOffset;
@property float previousPositionOffset;

@property double firstGetSeconds;

- (void)update;
- (void)setBuffer:(float *)buffer size:(int)size;
- (void)setByteOffset:(float)byteOffset;
- (float)getByteOffset;
- (void)beganScratching;
- (void)endedScratching;
- (double)getSeconds;
- (void)setVolume:(float)volume;
- (void)freeScratch;
- (void)stop;

@end

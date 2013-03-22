//
//  AudioScratchDemoViewController.h
//  AudioScratchDemo
//
//  Created by Jan Kalis on 10/22/10.
//  Copyright 2010 Glow Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "bass.h"

@class Scratcher;

@interface AudioScratchDemoViewController : UIViewController
{
	HSTREAM handle_;
	Scratcher* scratcher_;
	
	NSTimer* updateTimer_;
	UIImageView* vinyl_;
	
	float prevAngle_;
	float angleAccum_;
	float initialScratchPosition_;
	
	HSTREAM decoder_;
	
	FILE* mappedFile_;
	
	void* mappedMemory_;
	int mappedMemorySize_;

}
@property (retain, nonatomic) IBOutletCollection(UIButton) NSArray *botoes;

- (void)update:(NSTimer*)timer;

@end


//
//  AudioScratchDemoViewController.h
//  AudioScratchDemo
//
//  Created by Jan Kalis on 10/22/10.
//  Copyright 2010 Glow Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "bass.h"
#import "Scratcher.h"

@interface ScratcherViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView* vinyl;
@property (strong, nonatomic) NSString *mp3;
@property (readonly, nonatomic) HSTREAM channel;


@end


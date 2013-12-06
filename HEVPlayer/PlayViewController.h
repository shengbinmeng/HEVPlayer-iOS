//
//  PlayViewController.h
//  HEVPlayer
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MoviePlayer.h"

@interface PlayViewController : UIViewController

@property (nonatomic, retain) IBOutlet UILabel *infoLabel;
@property (nonatomic, retain) IBOutlet UIButton *doneButton;
@property (nonatomic, retain) MoviePlayer *player;
- (IBAction)doneButtonPressed:(id)sender;

@end

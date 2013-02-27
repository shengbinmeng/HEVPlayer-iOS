//
//  TextFieldCell.m
//  SVPlayer
//
//  Created by Meng Shengbin on 2/14/12.
//  Copyright (c) 2012 Peking University. All rights reserved.
//

#import "TextFieldCell.h"

@implementation TextFieldCell

@synthesize label, textField;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) dealloc 
{
    self.textField = nil;
    self.label = nil;
}

@end

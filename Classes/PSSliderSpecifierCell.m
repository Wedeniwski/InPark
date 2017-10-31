//
//  PSSliderSpecifierCell.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 05.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PSSliderSpecifierCell.h"
#import "InAppSettingConstants.h"
#import "IPadHelper.h"

@implementation PSSliderSpecifierCell

-(id)initWithSetting:(InAppSetting *)inputSetting reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
  if (self != nil) {
    //get the abolute path to the images
    NSString *settingsBundlePath = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    NSString *minImagePath = [settingsBundlePath stringByAppendingPathComponent:[self.setting valueForKey:@"MinimumValueImage"]];
    NSString *maxImagePath = [settingsBundlePath stringByAppendingPathComponent:[self.setting valueForKey:@"MaximumValueImage"]];
    
    //create the slider
    valueSlider = [[UISlider alloc] initWithFrame:CGRectZero];
    valueSlider.minimumValue = [[self.setting valueForKey:@"MinimumValue"] floatValue];
    valueSlider.maximumValue = [[self.setting valueForKey:@"MaximumValue"] floatValue];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:minImagePath];
    valueSlider.minimumValueImage = image;
    [image release];
    image = [[UIImage alloc] initWithContentsOfFile:maxImagePath];
    valueSlider.maximumValueImage = image;
    [image release];
    CGRect valueSliderFrame = valueSlider.frame;
    valueSliderFrame.origin.y = (CGFloat)round((self.contentView.frame.size.height*0.5f)-(valueSliderFrame.size.height*0.5f));
    valueSliderFrame.origin.x = [self inAppSettingCellPadding];
    valueSliderFrame.size.width = [self inAppSettingTableWidth]-[self inAppSettingCellPadding]*4;
    valueSlider.frame = valueSliderFrame;
    [valueSlider addTarget:self action:@selector(slideAction) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:valueSlider];
  }
  return self;
}

- (void)slideAction{
  [self setValue:[NSNumber numberWithFloat:[valueSlider value]]];
}

- (void)setValue{
  [super setValue];
  
  valueSlider.value = [[self getValue] floatValue];
}

-(void)setupCell:(InAppSetting *)inputSetting {
  [super setupCell:inputSetting];
}

- (void)dealloc{
  [valueSlider release];
  [super dealloc];
}

@end

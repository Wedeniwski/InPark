//
//  PSToggleSwitchSpecifierCell.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 05.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PSToggleSwitchSpecifierCell.h"
#import "InAppSettingConstants.h"

@implementation PSToggleSwitchSpecifierCell

-(id)initWithSetting:(InAppSetting *)inputSetting reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithSetting:inputSetting reuseIdentifier:reuseIdentifier];
  if (self != nil) {
    //create the switch
    valueSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    CGRect valueSwitchFrame = valueSwitch.frame;
    valueSwitchFrame.origin.y = (CGFloat)round((self.contentView.frame.size.height*0.5f)-(valueSwitchFrame.size.height*0.5f));
    valueSwitchFrame.origin.x = (CGFloat)round(([self inAppSettingTableWidth]-[self inAppSettingCellPadding]*3)-valueSwitchFrame.size.width);
    valueSwitch.frame = valueSwitchFrame;
    [valueSwitch addTarget:self action:@selector(switchAction) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:valueSwitch];
    //[valueSwitch release];
  }
  return self;
}

-(BOOL)getBool {
  id value = [self getValue];
  if ([value isEqual:[setting valueForKey:@"TrueValue"]]) return YES;
  if ([value isEqual:[setting valueForKey:@"FalseValue"]]) return NO;
  //if there is no true or false values the value has to be a bool
  return [value boolValue];
}

-(void)setBool:(BOOL)newValue {
  id value = [NSNumber numberWithBool:newValue];
  if (newValue) {
    id trueValue = [setting valueForKey:@"TrueValue"];
    if (trueValue) {
      value = trueValue;
    }
  } else {
    id falseValue = [setting valueForKey:@"FalseValue"];
    if (falseValue) {
      value = falseValue;
    }
  }
  [self setValue:value];
}

-(void)switchAction {
  [self setBool:[valueSwitch isOn]];
}

-(void)setValue {
  [super setValue];
  valueSwitch.on = [self getBool];
}

-(void)setupCell:(InAppSetting *)inputSetting {
  [super setupCell:inputSetting];
  [self setTitle];
  [self setDisclosure:NO];
}

-(void)dealloc{
  [valueSwitch release];
  [super dealloc];
}

@end
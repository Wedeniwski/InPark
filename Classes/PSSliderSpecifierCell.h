//
//  PSSliderSpecifierCell.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 05.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InAppSettingsTableCell.h"

@interface PSSliderSpecifierCell : InAppSettingsTableCell {
  UISlider *valueSlider;
}

-(id)initWithSetting:(InAppSetting *)inputSetting reuseIdentifier:(NSString *)reuseIdentifier;
-(void)slideAction;

@end
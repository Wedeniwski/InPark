//
//  PSToggleSwitchSpecifierCell.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 05.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InAppSettingsTableCell.h"

@interface PSToggleSwitchSpecifierCell : InAppSettingsTableCell {
  UISwitch *valueSwitch;
}

-(id)initWithSetting:(InAppSetting *)inputSetting reuseIdentifier:(NSString *)reuseIdentifier;
-(BOOL)getBool;
-(void)setBool:(BOOL)newValue;
-(void)switchAction;

@end
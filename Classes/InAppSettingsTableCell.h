//
//  InAppSettingsTableCell.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 05.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InAppSetting.h"

@interface InAppSettingsTableCell : UITableViewCell {
  InAppSetting *setting;
  UILabel *titleLabel, *valueLabel;
}

-(id)initWithSetting:(InAppSetting *)inputSetting reuseIdentifier:(NSString *)reuseIdentifier;
-(void)setupCell:(InAppSetting *)inputSetting;

-(float)inAppSettingTableWidth;
-(float)inAppSettingCellPadding;
-(void)setTitle;
-(void)setDetail;
-(void)setTitle:(NSString *)title;
-(void)setDetail:(NSString *)detail;
-(void)setDisclosure:(BOOL)disclosure;

-(id)getValue;
-(void)setValue;
-(void)setValue:(id)newValue;
-(UIControl *)getValueInput;

@property (nonatomic, retain) InAppSetting *setting;

@end
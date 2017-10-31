//
//  PSTextFieldSpecifierCell.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 05.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InAppSettingsTableCell.h"

@interface PSTextFieldSpecifierCell : InAppSettingsTableCell {
  UITextField *textField;
}

-(id)initWithSetting:(InAppSetting *)inputSetting reuseIdentifier:(NSString *)reuseIdentifier;
-(BOOL)isSecure;
-(UIKeyboardType)getKeyboardType;
-(UITextAutocapitalizationType)getAutocapitalizationType;
-(UITextAutocorrectionType)getAutocorrectionType;
-(void)textChangeAction;

@end
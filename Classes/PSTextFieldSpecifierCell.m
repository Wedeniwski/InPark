//
//  PSTextFieldSpecifierCell.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 05.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "PSTextFieldSpecifierCell.h"
#import "InAppSettingConstants.h"
#import "IPadHelper.h"
#import "Colors.h"

@implementation PSTextFieldSpecifierCell

-(id)initWithSetting:(InAppSetting *)inputSetting reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
  if (self != nil) {
    CGSize titleSize = [titleLabel.text sizeWithAttributes:@{NSFontAttributeName:titleLabel.font}];
    //CGSize titleSize = [titleLabel.text sizeWithFont:titleLabel.font];
    
    // create text field
    textField = [[UITextField alloc] initWithFrame:CGRectZero];
    textField.textColor = [Colors settingColor];
    textField.adjustsFontSizeToFitWidth = YES;
    
    // keyboard traits
    textField.secureTextEntry = [self isSecure];
    textField.keyboardType = [self getKeyboardType];
    textField.autocapitalizationType = [self getAutocapitalizationType];
    textField.autocorrectionType = [self getAutocorrectionType];
    
    CGRect textFieldFrame = textField.frame;
    textFieldFrame.origin.x = (CGFloat)round(titleSize.width+[self inAppSettingCellPadding]*2);
    if (textFieldFrame.origin.x < InAppSettingCellTextFieldMinX) {
      textFieldFrame.origin.x = InAppSettingCellTextFieldMinX;
    }
    textFieldFrame.origin.y = (CGFloat)round((self.contentView.frame.size.height*0.5f)-(titleSize.height*0.5f));
    textFieldFrame.size.width = (CGFloat)round(([self inAppSettingTableWidth]-[self inAppSettingCellPadding]*3)-textFieldFrame.origin.x);
    textFieldFrame.size.height = titleSize.height;
    textField.frame = textFieldFrame;
    
    [textField addTarget:self action:@selector(textChangeAction) forControlEvents:UIControlEventEditingChanged];
    [self.contentView addSubview:textField];
  }
  return self;
}

- (BOOL)isSecure{
  NSNumber *isSecure = [self.setting valueForKey:@"IsSecure"];
  if(!isSecure){
    return NO;
  }
  return [isSecure boolValue];
}

- (UIKeyboardType)getKeyboardType{
  NSString *keyboardType = [self.setting valueForKey:@"KeyboardType"];
  if([keyboardType isEqualToString:@"NumbersAndPunctuation"]){
    return UIKeyboardTypeNumbersAndPunctuation;
  }
  else if([keyboardType isEqualToString:@"NumberPad"]){
    return UIKeyboardTypeNumberPad;
  }
  else if([keyboardType isEqualToString:@"URL"]){
    return UIKeyboardTypeURL;
  }    
  else if([keyboardType isEqualToString:@"EmailAddress"]){
    return UIKeyboardTypeEmailAddress;
  } 
  
  return UIKeyboardTypeAlphabet;
}

- (UITextAutocapitalizationType)getAutocapitalizationType{
  //this works, but the real settings don't seem to respect these values eventhough they are in the docs
  NSString *autoCapitalizationType = [self.setting valueForKey:@"AutoCapitalizationType"];
  if([autoCapitalizationType isEqualToString:@"Words"]){
    return UITextAutocapitalizationTypeWords;
  }
  else if([autoCapitalizationType isEqualToString:@"Sentences"]){
    return UITextAutocapitalizationTypeSentences;
  }
  else if([autoCapitalizationType isEqualToString:@"AllCharacters"]){
    return UITextAutocapitalizationTypeAllCharacters;
  }
  return UITextAutocapitalizationTypeNone;
}

- (UITextAutocorrectionType)getAutocorrectionType{
  NSString *autocorrectionType = [self.setting valueForKey:@"AutocorrectionType"];
  if([autocorrectionType isEqualToString:@"Yes"]){
    return UITextAutocorrectionTypeYes;
  }
  else if([autocorrectionType isEqualToString:@"No"]){
    return UITextAutocorrectionTypeNo;
  }
  return UITextAutocorrectionTypeDefault;
}

- (void)textChangeAction{
  [self setValue:textField.text];
}

- (void)setValue{
  [super setValue];
  
  textField.text = [self getValue];
}

- (UIControl *)getValueInput{
  return textField;
}

-(void)setupCell:(InAppSetting *)inputSetting {
  [super setupCell:inputSetting];
  [self setTitle];
}

- (void)dealloc{
  [textField release];
  [super dealloc];
}

@end


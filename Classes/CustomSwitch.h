//
//  CustomSwitch.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 26.11.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CustomSwitchDelegate;

@interface CustomSwitch : UISlider {
	id <CustomSwitchDelegate> delegate;
	BOOL on;
	UIColor *tintColor;
	UIView *clippingView;
  UIImageView *leftImageView;
  UIImageView *rightImageView;
}

@property (nonatomic, assign) id <CustomSwitchDelegate> delegate;
@property (nonatomic,getter=isOn) BOOL on;
@property (nonatomic,retain) UIColor *tintColor;
@property (nonatomic,retain) UIView *clippingView;
@property (nonatomic,retain) UIImageView *leftImageView;
@property (nonatomic,retain) UIImageView *rightImageView;

-(void)setOn:(BOOL)on animated:(BOOL)animated;

@end

@protocol CustomSwitchDelegate <NSObject>
@optional
-(void)customSwitchDelegate:(CustomSwitch *)customSwitch selectionDidChange:(BOOL)on;
@end

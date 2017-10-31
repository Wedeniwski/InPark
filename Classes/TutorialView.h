//
//  TutorialView.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 24.05.12.
//  Copyright (c) 2012 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TutorialViewDelegate
-(void)endTutorial;
@end

@interface TutorialView : UIView {
  UIViewController<TutorialViewDelegate> *delegate;
  NSMutableArray *frames;
  NSMutableArray *text;
  NSMutableArray *directions;
  NSMutableArray *position;
}

-(void)setOwner:(UIViewController<TutorialViewDelegate> *)owner;
-(void)addFrame:(CGRect)rect alignmentLeft:(BOOL)alignmentLeft alignmentBottom:(BOOL)alignmentBottom withText:(NSString *)text;
-(void)addLabelFrame:(CGRect)rect withText:(NSString *)text;
-(void)clear;

@end

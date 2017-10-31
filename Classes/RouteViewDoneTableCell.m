//
//  RouteViewDoneTableCell.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 23.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "RouteViewDoneTableCell.h"

@implementation RouteViewDoneTableCell

@synthesize iconButton;
@synthesize attractionNameLabel, entryAttractionNameLabel, exitAttractionNameLabel, ratingLabel, timeLabel;
@synthesize ratingView;

-(void)dealloc {
  [iconButton release];
  [attractionNameLabel release];
  [entryAttractionNameLabel release];
  [exitAttractionNameLabel release];
  [ratingLabel release];
  [timeLabel release];
  [ratingView release];
  [super dealloc];
}

-(void)setCompleted:(BOOL)completed {
  iconButton.imageView.image = [UIImage imageNamed:(completed)? @"checkmark40.png" : @"cross40.png"];
  iconButton.imageView.clipsToBounds = YES;
}

@end

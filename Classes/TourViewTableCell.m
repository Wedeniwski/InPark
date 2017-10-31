//
//  TourViewTableCell.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 11.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "TourViewTableCell.h"
#import "TourViewController.h"

@implementation TourViewTableCell

@synthesize iconButton;
@synthesize closedView;
@synthesize distanceLabel, currentDistanceLabel, attractionNameLabel, entryAttractionNameLabel, exitAttractionNameLabel;
@synthesize timeLabel;

-(void)dealloc {
  [iconName release];
  [iconButton release];
  [closedView release];
  [distanceLabel release];
  [currentDistanceLabel release];
  [attractionNameLabel release];
  [entryAttractionNameLabel release];
  [exitAttractionNameLabel release];
  [timeLabel release];
  [super dealloc];
}

-(void)setIconName:(NSString *)newIconName {
  if (newIconName == nil) {
    [iconName release];
    iconName = nil;
    [iconButton setImage:nil forState:UIControlStateNormal];
  } else if (iconName == nil || ![iconName isEqualToString:newIconName]) {
    [iconName release];
    iconName = [newIconName retain];
    [iconButton setImage:[UIImage imageNamed:iconName] forState:UIControlStateNormal];
    iconButton.imageView.clipsToBounds = YES;
  }
}

-(void)setCompleted:(BOOL)completed {
  iconButton.hidden = NO;
  iconButton.enabled = NO;
  [self setIconName:(completed)? @"checkmark40.png" : @"cross40.png"];
}

-(void)setClosed:(BOOL)closed {
  closedView.hidden = !closed;
  iconButton.hidden = closed;
  timeLabel.hidden = closed;
}

-(IBAction)switchDone:(id)sender {
  if ([sender isKindOfClass:[UIButton class]] && [self.delegate isKindOfClass:[TourViewController class]]) {
    UIButton *b = (UIButton *)sender;
    TourViewController *controller = (TourViewController *)self.delegate;
    [controller switchAttractionDone:b.tag closed:!closedView.hidden toTourItem:YES];
  }
}

@end

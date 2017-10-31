//
//  RouteViewTableCell.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 22.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "RouteViewTableCell.h"
#import "TourViewController.h"

@implementation RouteViewTableCell

@synthesize toTourItem;
@synthesize iconButton;
@synthesize closedView;
@synthesize attractionNameLabel, entryAttractionNameLabel, exitAttractionNameLabel, locationLabel, descriptionLabel, timeLabel, openingTimeLabel, waitingTimeLabel;

-(void)dealloc {
  [iconName release];
  [iconButton release];
  [closedView release];
  [attractionNameLabel release];
  [entryAttractionNameLabel release];
  [exitAttractionNameLabel release];
  [locationLabel release];
  [descriptionLabel release];
  [timeLabel release];
  [openingTimeLabel release];
  [waitingTimeLabel release];
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

-(void)setClosed:(BOOL)closed {
  closedView.hidden = !closed;
  iconButton.hidden = closed;
  timeLabel.hidden = closed;
}

-(IBAction)switchDone:(id)sender {
  if ([sender isKindOfClass:[UIButton class]] && [self.delegate isKindOfClass:[TourViewController class]]) {
    UIButton *b = (UIButton *)sender;
    TourViewController *controller = (TourViewController *)self.delegate;
    [controller switchAttractionDone:(int)b.tag closed:!closedView.hidden toTourItem:toTourItem];
  }
}

@end

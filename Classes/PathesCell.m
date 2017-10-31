//
//  PathesCell.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.02.12.
//  Copyright (c) 2012 InPark GbR. All rights reserved.
//

#import "PathesCell.h"

@implementation PathesCell

@synthesize attractionId;
@synthesize iconView;
@synthesize categoryLabel, attractionNameLabel, distanceLabel, waitingTimeLabel;
@synthesize waitingTimeBadge;
@synthesize waitingTimeButton;
@synthesize favoriteView, closedImageView;

-(void)dealloc {
  [attractionId release];
  [iconView release];
  [categoryLabel release];
  [attractionNameLabel release];
  [distanceLabel release];
  [waitingTimeLabel release];
  [waitingTimeBadge release];
  [waitingTimeButton release];
  [favoriteView release];
  [closedImageView release];
  [super dealloc];
}

-(void)setIconPath:(NSString *)newIconPath {
  [iconView setImagePath:newIconPath];
}

-(void)setCategory:(NSString *)newCategory {
  categoryLabel.text = (newCategory != nil)? newCategory : @"";
}

-(void)setAttractionId:(NSString *)aId name:(NSString *)newAttractionName {
  [attractionId release];
  attractionId = [aId retain];
  attractionNameLabel.text = (newAttractionName != nil)? newAttractionName : @"";
}

-(IBAction)waitingTime:(id)sender {
  [delegate changingWaitingTimeForAttractionId:attractionId];
}

-(IBAction)switchFavorite:(id)sender {
  [delegate switchFavoriteForAttractionId:attractionId];
}

@end

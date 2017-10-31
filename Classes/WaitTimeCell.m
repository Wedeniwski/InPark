//
//  WaitTimeCell.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.02.12.
//  Copyright (c) 2012 InPark GbR. All rights reserved.
//

#import "WaitTimeCell.h"

@implementation WaitTimeCell

@synthesize userNameLabel, submittedTimestampLabel;
@synthesize waitingTimeBadge;
@synthesize closedImageView;

-(void)dealloc {
  [userNameLabel release];
  [submittedTimestampLabel release];
  [waitingTimeBadge release];
  [closedImageView release];
  [super dealloc];
}

@end

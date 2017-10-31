//
//  WaitTimeCell.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.02.12.
//  Copyright (c) 2012 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableCell.h"
#import "CustomBadge.h"

@interface WaitTimeCell : TableCell {
  IBOutlet UILabel *userNameLabel;
  IBOutlet UILabel *submittedTimestampLabel;
  IBOutlet CustomBadge *waitingTimeBadge;
  IBOutlet UIImageView *closedImageView;
}

@property (retain, nonatomic) UILabel *userNameLabel;
@property (retain, nonatomic) UILabel *submittedTimestampLabel;
@property (retain, nonatomic) CustomBadge *waitingTimeBadge;
@property (retain, nonatomic) UIImageView *closedImageView;

@end
//
//  TourViewTableCell.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 11.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableCell.h"

@interface TourViewTableCell : TableCell {
  NSString *iconName;

  IBOutlet UIButton *iconButton;
  IBOutlet UIImageView *closedView;
  IBOutlet UILabel *distanceLabel;
  IBOutlet UILabel *currentDistanceLabel;
  IBOutlet UILabel *attractionNameLabel;
  IBOutlet UILabel *entryAttractionNameLabel;
  IBOutlet UILabel *exitAttractionNameLabel;
  IBOutlet UILabel *timeLabel;
}

-(void)setIconName:(NSString *)newIconName;
-(void)setCompleted:(BOOL)completed;
-(void)setClosed:(BOOL)closed;
-(IBAction)switchDone:(id)sender;

@property (retain, nonatomic) UIButton *iconButton;
@property (retain, nonatomic) UIImageView *closedView;
@property (retain, nonatomic) UILabel *distanceLabel;
@property (retain, nonatomic) UILabel *currentDistanceLabel;
@property (retain, nonatomic) UILabel *attractionNameLabel;
@property (retain, nonatomic) UILabel *entryAttractionNameLabel;
@property (retain, nonatomic) UILabel *exitAttractionNameLabel;
@property (retain, nonatomic) UILabel *timeLabel;

@end

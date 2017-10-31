//
//  RouteViewTableCell.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 22.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableCell.h"

@interface RouteViewTableCell : TableCell {
  BOOL toTourItem;
  NSString *iconName;

  IBOutlet UIButton *iconButton;
  IBOutlet UIImageView *closedView;
  IBOutlet UILabel *attractionNameLabel;
  IBOutlet UILabel *entryAttractionNameLabel;
  IBOutlet UILabel *exitAttractionNameLabel;
  IBOutlet UILabel *locationLabel;
  IBOutlet UILabel *descriptionLabel;
  IBOutlet UILabel *timeLabel;
  IBOutlet UILabel *openingTimeLabel;
  IBOutlet UILabel *waitingTimeLabel;
}

-(void)setIconName:(NSString *)newIconName;
-(void)setClosed:(BOOL)closed;
-(IBAction)switchDone:(id)sender;

@property BOOL toTourItem;
@property (retain, nonatomic) UIButton *iconButton;
@property (retain, nonatomic) UIImageView *closedView;
@property (retain, nonatomic) UILabel *attractionNameLabel;
@property (retain, nonatomic) UILabel *entryAttractionNameLabel;
@property (retain, nonatomic) UILabel *exitAttractionNameLabel;
@property (retain, nonatomic) UILabel *locationLabel;
@property (retain, nonatomic) UILabel *descriptionLabel;
@property (retain, nonatomic) UILabel *timeLabel;
@property (retain, nonatomic) UILabel *openingTimeLabel;
@property (retain, nonatomic) UILabel *waitingTimeLabel;

@end

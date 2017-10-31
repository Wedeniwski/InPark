//
//  RouteViewHighLightTableCell.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 23.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableCell.h"

@interface RouteViewHighLightTableCell : TableCell {
@private
  BOOL toTourItem;
  NSURLConnection *connection;
  NSMutableData *data;
  NSString *iconName;
  NSString *imagePath;
  
@public
  IBOutlet UIImageView *imageView;
  IBOutlet UIButton *iconButton;
  IBOutlet UILabel *attractionNameLabel;
  IBOutlet UILabel *attractionName2Label;
  IBOutlet UILabel *descriptionLabel;
  IBOutlet UILabel *timeLabel;
  IBOutlet UILabel *detailDescriptionLabel;
  IBOutlet UILabel *waitingTimeLabel;
}

-(void)setIconName:(NSString *)newIconName;
-(void)setImagePath:(NSString *)newImagePath;
-(IBAction)switchDone:(id)sender;

@property BOOL toTourItem;
@property (retain, nonatomic) UIImageView *imageView;
@property (retain, nonatomic) UIButton *iconButton;
@property (retain, nonatomic) UILabel *attractionNameLabel;
@property (retain, nonatomic) UILabel *attractionName2Label;
@property (retain, nonatomic) UILabel *descriptionLabel;
@property (retain, nonatomic) UILabel *timeLabel;
@property (retain, nonatomic) UILabel *detailDescriptionLabel;
@property (retain, nonatomic) UILabel *waitingTimeLabel;

@end

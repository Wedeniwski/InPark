//
//  PathesCell.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.02.12.
//  Copyright (c) 2012 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableCell.h"
#import "AsynchronousImageView.h"
#import "CustomBadge.h"

@protocol PathesCellDelegate
-(void)changingWaitingTimeForAttractionId:(NSString *)attractionId;
-(void)switchFavoriteForAttractionId:(NSString *)attractionId;
@end

@interface PathesCell : TableCell {
  NSString *attractionId;

  IBOutlet AsynchronousImageView *iconView;
  IBOutlet UILabel *categoryLabel;
  IBOutlet UILabel *attractionNameLabel;
  IBOutlet UILabel *distanceLabel;
  IBOutlet UILabel *waitingTimeLabel;
  IBOutlet CustomBadge *waitingTimeBadge;
  IBOutlet UIButton *waitingTimeButton;
  IBOutlet UIImageView *favoriteView;
  IBOutlet UIImageView *closedImageView;
}

-(void)setIconPath:(NSString *)newIconPath;
-(void)setCategory:(NSString *)newCategory;
-(void)setAttractionId:(NSString *)aId name:(NSString *)newAttractionName;

-(IBAction)waitingTime:(id)sender;
-(IBAction)switchFavorite:(id)sender;

@property (readonly) NSString *attractionId;
@property (retain, nonatomic) AsynchronousImageView *iconView;
@property (retain, nonatomic) UILabel *categoryLabel;
@property (retain, nonatomic) UILabel *attractionNameLabel;
@property (retain, nonatomic) UILabel *distanceLabel;
@property (retain, nonatomic) UILabel *waitingTimeLabel;
@property (retain, nonatomic) CustomBadge *waitingTimeBadge;
@property (retain, nonatomic) UIButton *waitingTimeButton;
@property (retain, nonatomic) UIImageView *favoriteView;
@property (retain, nonatomic) UIImageView *closedImageView;

@end
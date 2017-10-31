//
//  RouteViewDoneTableCell.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 23.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableCell.h"
#import "PreferenceFitView.h"

@interface RouteViewDoneTableCell : TableCell {
  IBOutlet UIButton *iconButton;
  IBOutlet UILabel *attractionNameLabel;
  IBOutlet UILabel *entryAttractionNameLabel;
  IBOutlet UILabel *exitAttractionNameLabel;
  IBOutlet UILabel *ratingLabel;
  IBOutlet UILabel *timeLabel;
  IBOutlet PreferenceFitView *ratingView;
}

-(void)setCompleted:(BOOL)completed;

@property (retain, nonatomic) UIButton *iconButton;
@property (retain, nonatomic) UILabel *attractionNameLabel;
@property (retain, nonatomic) UILabel *entryAttractionNameLabel;
@property (retain, nonatomic) UILabel *exitAttractionNameLabel;
@property (retain, nonatomic) UILabel *ratingLabel;
@property (retain, nonatomic) UILabel *timeLabel;
@property (retain, nonatomic) PreferenceFitView *ratingView;

@end

//
//  CalendarViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 13.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MADayView.h"

@interface CalendarViewController : UIViewController <MADayViewDataSource, MADayViewDelegate> {
  id delegate;
  NSMutableSet *seeMoreAttractionIds;
  UIBarButtonItem *seeMoreBarButtonItem;
  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleNavigationItem;
	IBOutlet UIView *headerView;
	IBOutlet UIView *calendarView;
	IBOutlet UILabel *monthTitle;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId title:(NSString *)tName;

-(IBAction)loadBackView:(id)sender;
-(IBAction)dayView:(id)sender;
-(IBAction)seeMoreEventsView:(id)sender;
-(IBAction)prevMonth:(id)sender;
-(IBAction)nextMonth:(id)sender;

-(void)createCalendar;
-(void)fillCalendar;
-(void)setCurrentDate:(NSDate *)value;

@property (readonly) id delegate;
@property (nonatomic, retain) UINavigationBar *topNavigationBar;
@property (nonatomic, retain) UINavigationItem *titleNavigationItem;
@property (nonatomic, retain) UIView *headerView;
@property (nonatomic, retain) UIView *calendarView;
@property (nonatomic, retain) UILabel *monthTitle;

@end

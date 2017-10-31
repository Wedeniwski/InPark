//
//  ImagesSelectionViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 18.09.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AQGridView.h"

@interface ImagesSelectionViewController : UIViewController <AQGridViewDelegate, AQGridViewDataSource, UITextViewDelegate> {
	id delegate;
  BOOL canceled;
  NSString *parkId;
  NSArray *attractions;
  NSString *titleName;
  NSString *location;
  NSString *description;
  NSMutableArray *information;
  NSMutableArray *imagePathes;
  NSDictionary *localImageData;
  UITextView *titleNameTextView;
  UITextView *locationTextView;
  UITextView *descriptionTextView;
  
  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleNavigationItem;
  IBOutlet AQGridView *gridView;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId attractions:(NSArray *)attractions titleName:(NSString *)tName location:(NSString *)loc description:(NSString *)text information:(NSArray *)info;

-(void)setImagePath:(NSString *)imagePath atIndex:(int)index;
-(const char *)attractionNameAtIndex:(int)index;
-(IBAction)loadBackView:(id)sender;
-(IBAction)cancel:(id)sender;

@property (readonly) BOOL canceled;
@property (nonatomic, readonly) NSString *titleName;
@property (nonatomic, readonly) NSString *location;
@property (nonatomic, readonly) NSString *description;
@property (nonatomic, readonly) NSArray *information;
@property (nonatomic, readonly) NSArray *imagePathes;
@property (nonatomic, retain) UINavigationBar *topNavigationBar;
@property (nonatomic, retain) UINavigationItem *titleNavigationItem;
@property (nonatomic, retain) AQGridView *gridView;

@end

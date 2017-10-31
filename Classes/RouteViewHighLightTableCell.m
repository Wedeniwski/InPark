//
//  RouteViewHighLightTableCell.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 23.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "RouteViewHighLightTableCell.h"
#import "TourViewController.h"

@implementation RouteViewHighLightTableCell

@synthesize toTourItem;
@synthesize imageView;
@synthesize iconButton;
@synthesize attractionNameLabel, attractionName2Label, descriptionLabel, timeLabel, detailDescriptionLabel, waitingTimeLabel;

-(void)dealloc {
  [iconName release];
  [imagePath release];
  [imageView release];
  [iconButton release];
  [attractionNameLabel release];
  [attractionName2Label release];
  [descriptionLabel release];
  [timeLabel release];
  [detailDescriptionLabel release];
  [waitingTimeLabel release];
  [super dealloc];
}

-(void)setIconName:(NSString *)newIconName {
  if (newIconName == nil) {
    [iconName release];
    iconName = nil;
    [iconButton setImage:nil forState:UIControlStateNormal];
  } else if (iconName == nil || ![iconName isEqualToString:newIconName]) {
    [iconName release];
    iconName = [newIconName retain];
    [iconButton setImage:[UIImage imageNamed:iconName] forState:UIControlStateNormal];
    iconButton.imageView.clipsToBounds = YES;
  }
}

-(void)setImagePath:(NSString *)newImagePath {
  if (newImagePath == nil) {
    [imagePath release];
    imagePath = nil;
    imageView.image = nil;
  } else if (imagePath == nil || ![imagePath isEqualToString:newImagePath]) {
    [imagePath release];
    imagePath = [newImagePath retain];
    //[imageView.image release];
    imageView.image = nil;
    //NSString *bPath = [[NSBundle mainBundle] pathForResource:newImageName ofType:nil];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:newImagePath isDirectory:NO];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:15.0];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [url release];
  }
}

-(void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData {
  if (data == nil) {
    data = [[NSMutableData alloc] initWithCapacity:MAX([incrementalData length], 4096)];
  }
  [data appendData:incrementalData];
}

-(void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)error {
  [data release];
  data = nil;
  [connection release];
  connection = nil;
}

-(void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
  imageView.layer.masksToBounds = YES;
  imageView.layer.cornerRadius = 5.0;
  imageView.image = [UIImage imageWithData:data];
  imageView.clipsToBounds = YES;
  [data release];
  data = nil;
  [connection release];
  connection = nil;
}

-(IBAction)switchDone:(id)sender {
  if ([sender isKindOfClass:[UIButton class]] && [self.delegate isKindOfClass:[TourViewController class]]) {
    UIButton *b = (UIButton *)sender;
    TourViewController *controller = (TourViewController *)self.delegate;
    [controller switchAttractionDone:(int)b.tag closed:NO toTourItem:toTourItem];
  }
}

@end

//
//  AsynchronousImageView.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.09.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AsynchronousImageView : UIView {
@private
  NSURLConnection *connection;
  NSMutableData *data;
  NSString *imagePath;

@public
  UIImageView *imageView;
  UIActivityIndicatorView *activityIndicator;   
}

-(BOOL)isEqual:(id)object;

-(void)setFrame:(CGRect)frame;
-(void)setBorderWidth:(float)borderWidth;
-(void)setImage:(UIImage *)newImage;
-(void)setImagePath:(NSString *)newImagePath;

+(UIImage *)ensureSmallImageCreatedFor:(UIImage *)image atPath:(NSString *)imagePath;
+(NSString *)smallImagePathFor:(NSString *)imagePath;

@property (nonatomic, readonly) NSString *imagePath;
@property (nonatomic, retain) UIImageView *imageView;

@end

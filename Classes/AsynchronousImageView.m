//
//  AsynchronousImageView.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.09.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "AsynchronousImageView.h"
#import "ImageData.h"

@implementation AsynchronousImageView

@synthesize imagePath;
@synthesize imageView;

-(id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self != nil) {
    frame.origin.x = 0.0f;
    frame.origin.y = 0.0f;
    imageView = [[UIImageView alloc] initWithFrame:frame];
    activityIndicator = [[UIActivityIndicatorView alloc] init];
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    activityIndicator.hidesWhenStopped = YES;
    CGFloat xPos = frame.size.width*0.5f-10.0f;
    CGFloat yPos = frame.size.height*0.5f-10.0f;
    CGFloat width = 20.0f;
    CGFloat height = 20.0f;
    activityIndicator.frame = CGRectMake(xPos, yPos, width, height);    
    [self addSubview:imageView];
    [self addSubview:activityIndicator];
  }  
  return self;
}

-(void)dealloc {
  [imageView release];
  imageView = nil;
  [activityIndicator release];
  activityIndicator = nil;
  if (connection != nil) {
    NSLog(@"Active connection cancelled for %@", imagePath);
    [connection cancel];
    [connection release];
    connection = nil;
  }
  [data release];
  data = nil;
  [imagePath release];
  imagePath = nil;
  [super dealloc];
}

-(BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[AsynchronousImageView class]]) return NO;
  AsynchronousImageView *image = (AsynchronousImageView *)object;
  return [imageView isEqual:image.imageView];
}

-(void)setFrame:(CGRect)frame {
  [super setFrame:frame];
  if (imageView == nil) {
    frame.origin.x = 0.0f;
    frame.origin.y = 0.0f;
    imageView = [[UIImageView alloc] initWithFrame:frame];
    activityIndicator = [[UIActivityIndicatorView alloc] init];
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    activityIndicator.hidesWhenStopped = YES;
    CGFloat xPos = frame.size.width*0.5f-10.0f;
    CGFloat yPos = frame.size.height*0.5f-10.0f;
    CGFloat width = 20.0f;
    CGFloat height = 20.0f;
    activityIndicator.frame = CGRectMake(xPos, yPos, width, height);    
    [self addSubview:imageView];
    [self addSubview:activityIndicator];
  }
}

-(void)setBorderWidth:(float)borderWidth {
  imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
  imageView.layer.borderWidth = borderWidth;
}

-(void)setImage:(UIImage *)newImage {
  [activityIndicator stopAnimating];
  imageView.alpha = 0;
  imageView.layer.masksToBounds = YES;
  imageView.layer.cornerRadius = (self.frame.size.height >= 200.0f)? 8.0 : 5.0;
  imageView.image = newImage;
  imageView.clipsToBounds = YES;
  float w = newImage.size.width;
	float h = newImage.size.height;
  float f = self.bounds.size.width / MAX(h, w);
  w *= f; h *= f;
  imageView.frame = CGRectMake(0.0f, 0.0f, w, h);

  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.5];
  imageView.alpha = 1;
  [UIView commitAnimations];
}

-(void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData {
  if (data == nil) {
    data = [[NSMutableData alloc] initWithCapacity:MAX([incrementalData length], 4096)];
  }
  [data appendData:incrementalData];
}

-(void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)error {
  NSLog(@"set image path %@ failed (%@)", imagePath, [error localizedDescription]);
  [activityIndicator stopAnimating];
  [data release];
  data = nil;
  [connection release];
  connection = nil;
}

-(void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
  UIImage *image = [[UIImage alloc] initWithData:data];
  [self setImage:[AsynchronousImageView ensureSmallImageCreatedFor:image atPath:imagePath]];
  [image release];
  [data release];
  data = nil;
  [connection release];
  connection = nil;
}

/*-(void)startLoading {
  [activityIndicator startAnimating];
  NSURL *url = [[NSURL alloc] initFileURLWithPath:[AsynchronousImageView smallImagePathFor:imagePath] isDirectory:NO];
  NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:15.0];
  connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  [connection start];
  [url release];
}*/

-(void)setImagePath:(NSString *)newImagePath {
  if (imagePath != nil && [imagePath isEqualToString:newImagePath]) return;
  if (connection != nil) {
    NSLog(@"Active connection for %@ cancelled for %@", imagePath, newImagePath);
    [connection cancel];
    [connection release];
    connection = nil;
    [data release];
    data = nil;
  }
  if (newImagePath == nil) {
    [imagePath release];
    imagePath = nil;
    imageView.image = nil;
    [activityIndicator stopAnimating];
  //} else if (imagePath == nil) {
  } else {
    [imagePath release];
    imagePath = [newImagePath retain]; //[[NSString alloc] initWithString:newImagePath];
    NSRange range = [newImagePath rangeOfString:@"/"];
    if (range.length > 0) {
      imageView.image = nil;
      //[self performSelectorOnMainThread:@selector(startLoading) withObject:nil waitUntilDone:NO];
      [activityIndicator startAnimating];
      NSURL *url = [[NSURL alloc] initFileURLWithPath:[AsynchronousImageView smallImagePathFor:imagePath] isDirectory:NO];
      NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:15.0];
      connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
      [connection start];
      [url release];
    } else {
      imageView.image = [UIImage imageNamed:newImagePath];
    }
  }
}

+(UIImage *)ensureSmallImageCreatedFor:(UIImage *)image atPath:(NSString *)imagePath {
  CGSize size = image.size;
  if (size.width > 600.0f || size.height > 600.0f) {
    float f = 600.0f/MAX(size.width, size.height);
    size.width *= f;
    size.height *= f;
    UIImage *newImage = [ImageData rescaleImage:image toSize:size];
    [UIImageJPEGRepresentation(newImage, 0.9f) writeToFile:[AsynchronousImageView smallImagePathFor:imagePath] atomically:YES];
    return newImage;
  }
  return image;
}

+(NSString *)smallImagePathFor:(NSString *)imagePath {
  NSString *smallImagePath = [[imagePath substringToIndex:[imagePath length]-4] stringByAppendingString:@"s.jpg"];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  return [fileManager fileExistsAtPath:smallImagePath]? smallImagePath : imagePath;
}

@end

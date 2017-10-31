//
//  RouteView.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 21.10.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "RouteView.h"
#import "TrackPoint.h"
#import "RouteAnnotation.h"

#define ROUTE_WIDTH 4.0

@implementation RouteView
@synthesize mapView;
@synthesize selectedTrackPointIndex;
@synthesize viewDirection;

-(id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
  if (self) {
    mapView = nil;
    viewDirection = NO;
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;
    selectedTrackPointIndex = 0;
  }
  return self;
}

-(void)dealloc {
  [mapView release];
  mapView = nil;
  [super dealloc];
}

-(void)setMapView:(MKMapView *)map {
  if (map != mapView) {
    [mapView release];
    mapView = [map retain];
  }
  if (map != nil) {
    if (self.bounds.size.width == 0) {
      RouteAnnotation *annotation = self.annotation;
      //self.frame = CGRectMake(0, 0, map.frame.size.width, map.frame.size.height);
      CGRect rect = [mapView convertRegion:[annotation getRegion] toRectToView:map];
      rect.origin.x -= ROUTE_WIDTH; rect.origin.y -= ROUTE_WIDTH; rect.size.width += 2*ROUTE_WIDTH; rect.size.height += 2*ROUTE_WIDTH;
      //NSLog(@"%f, %f, %f, %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
      //NSLog(@"bounds %f, %f, %f, %f", self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
      self.frame = rect;
      //self.bounds = CGRectMake(0, 0, map.frame.size.width, map.frame.size.height);
    }
    [self setNeedsDisplay];
  }
}

+(UIImage *)rotateImage:(UIImage *)image rotate:(double)angle {
	/*
	 This method is not my work.
	 See: http://blog.logichigh.com/2008/06/05/uiimage-fix/
	 
	 One of the earliest bugs I had to face was related to image orientations.
	 UIImage stores its orientation in a separate property, which means that the
	 underlying CGImage sometimes has differend orientation and dimensions.
	 This method takes an UIImage and fixes this problem by returning an image that
	 has UIImageOrientationUp orientation, and therefore the CGImage and UIImage
	 representations produce the same results when drawing.
	 
	 It also scales back the image if requested
	 */
  CGImageRef imgRef = image.CGImage;
	
  CGFloat width = CGImageGetWidth(imgRef);
  CGFloat height = CGImageGetHeight(imgRef);
	
  //CGAffineTransform transform = CGAffineTransformIdentity;
  CGRect bounds = CGRectMake(0, 0, width, height);
  /*if (width > maxResolution || height > maxResolution) {
   CGFloat ratio = width/height;
   if (ratio > 1) {
   bounds.size.width = maxResolution;
   bounds.size.height = bounds.size.width / ratio;
   }
   else {
   bounds.size.height = maxResolution;
   bounds.size.width = bounds.size.height * ratio;
   }
   }
   
   CGFloat scaleRatio = bounds.size.width / width;
   CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
   CGFloat boundHeight;
   UIImageOrientation orient = image.imageOrientation;
   switch(orient) {
   
   case UIImageOrientationUp: //EXIF = 1
   transform = CGAffineTransformIdentity;
   if (width <= maxResolution && height <= maxResolution)
   {
   return image;
   }
   break;
   
   case UIImageOrientationUpMirrored: //EXIF = 2
   transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
   transform = CGAffineTransformScale(transform, -1.0, 1.0);
   break;
   
   case UIImageOrientationDown: //EXIF = 3
   transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
   transform = CGAffineTransformRotate(transform, M_PI);
   break;
   
   case UIImageOrientationDownMirrored: //EXIF = 4
   transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
   transform = CGAffineTransformScale(transform, 1.0, -1.0);
   break;
   
   case UIImageOrientationLeftMirrored: //EXIF = 5
   boundHeight = bounds.size.height;
   bounds.size.height = bounds.size.width;
   bounds.size.width = boundHeight;
   transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
   transform = CGAffineTransformScale(transform, -1.0, 1.0);
   transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
   break;
   
   case UIImageOrientationLeft: //EXIF = 6
   boundHeight = bounds.size.height;
   bounds.size.height = bounds.size.width;
   bounds.size.width = boundHeight;
   transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
   transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
   break;
   
   case UIImageOrientationRightMirrored: //EXIF = 7
   boundHeight = bounds.size.height;
   bounds.size.height = bounds.size.width;
   bounds.size.width = boundHeight;
   transform = CGAffineTransformMakeScale(-1.0, 1.0);
   transform = CGAffineTransformRotate(transform, M_PI / 2.0);
   break;
   
   case UIImageOrientationRight: //EXIF = 8
   boundHeight = bounds.size.height;
   bounds.size.height = bounds.size.width;
   bounds.size.width = boundHeight;
   transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
   transform = CGAffineTransformRotate(transform, M_PI / 2.0);
   break;
   
   default:
   [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
   }*/
	
  UIGraphicsBeginImageContext(bounds.size);
	
  CGContextRef context = UIGraphicsGetCurrentContext();
	
  /*if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
   CGContextScaleCTM(context, -scaleRatio, scaleRatio);
   CGContextTranslateCTM(context, -height, 0);
   }
   else {
   CGContextScaleCTM(context, scaleRatio, -scaleRatio);
   CGContextTranslateCTM(context, 0, -height);
   }
   
   CGContextConcatCTM(context, transform);*/
  CGContextRotateCTM(context, angle);
	
  CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
  UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
	
  return imageCopy;
}

-(void)drawRect:(CGRect)rect {
  if (!self.hidden) {
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor *lineColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];   // ToDo: configuration
    CGColorRef lineColorRef = lineColor.CGColor;
    // Draw them with a 2.0 stroke width so they are a bit more visible.
    CGContextSetLineWidth(context, ROUTE_WIDTH);
    RouteAnnotation *annotation = self.annotation;
    NSArray *tp = annotation.trackSegment.trackPoints;
    int l = (int)[tp count];
    if (l > 0) {
      TrackPoint *t = [tp objectAtIndex:0];
      CGPoint point = [mapView convertCoordinate:CLLocationCoordinate2DMake(t.latitude, t.longitude) toPointToView:self];
      if (viewDirection) { // Draw arrows
        UIImage *arrow = [UIImage imageNamed:@"right_arrow.png"]; // ToDo: static or more general
        CGContextSetStrokeColorWithColor(context, [lineColor colorWithAlphaComponent:0.5].CGColor);
        for (int i = 1; i < l; ++i) {
          t = [tp objectAtIndex:i];
          CGPoint nextPoint = [mapView convertCoordinate:CLLocationCoordinate2DMake(t.latitude, t.longitude) toPointToView:self];
          CGPoint centerPoint = CGPointMake((point.x+nextPoint.x)/2, (point.y+nextPoint.y)/2);
          double dx = nextPoint.x-point.x;
          double dy = nextPoint.y-point.y;
          double angle = atan2(dx, dy);
          UIImage *rotatedArrow = [RouteView rotateImage:arrow rotate:angle];
          CGContextDrawImage(context, CGRectMake(centerPoint.x, centerPoint.y, rotatedArrow.size.width, rotatedArrow.size.height), rotatedArrow.CGImage);
          point = nextPoint;
        }
        t = [tp objectAtIndex:0];
        point = [mapView convertCoordinate:CLLocationCoordinate2DMake(t.latitude, t.longitude) toPointToView:self];
      }
#ifdef DEBUG_MAP
      CGColorRef markColor = [UIColor redColor].CGColor;
      CGColorRef selectColor = [UIColor yellowColor].CGColor;
      CGRect rect = CGRectMake(point.x, point.y, 5.0, 5.0);
      for (int i = 0; i < l; ++i) {
        if (i == selectedTrackPointIndex) {
          CGContextSetStrokeColorWithColor(context, selectColor);
          CGContextSetRGBFillColor(context, 1.0, 1.0, 0.0, 1.0);
        } else {
          CGContextSetStrokeColorWithColor(context, markColor);
          CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
        }
        t = [tp objectAtIndex:i];
        point = [mapView convertCoordinate:CLLocationCoordinate2DMake(t.latitude, t.longitude) toPointToView:self];
        rect.origin.x = point.x-3; rect.origin.y = point.y-3;
        CGContextFillRect(context, rect);
      }
      static int swapSegmentColor = 0;
      if (++swapSegmentColor == 1) {
        CGContextSetStrokeColorWithColor(context, lineColorRef);
        CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 1.0);
      } else if (swapSegmentColor <= 10) {
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0.0 green:swapSegmentColor/10.0 blue:1.0/swapSegmentColor alpha:1.0].CGColor);
        CGContextSetRGBFillColor(context, 0.0, swapSegmentColor/10.0, 1.0/swapSegmentColor, 1.0);
      } else {
        swapSegmentColor = 0;
        CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
        CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
      }
      t = [tp objectAtIndex:0];
      point = [mapView convertCoordinate:CLLocationCoordinate2DMake(t.latitude, t.longitude) toPointToView:self];
#else
      CGContextSetStrokeColorWithColor(context, lineColorRef);
      CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 1.0);
#endif
      CGContextMoveToPoint(context, point.x, point.y);
      for (int i = 1; i < l; ++i) {
        t = [tp objectAtIndex:i];
        point = [mapView convertCoordinate:CLLocationCoordinate2DMake(t.latitude, t.longitude) toPointToView:self];
        CGContextAddLineToPoint(context, point.x, point.y);
      }
    }
    CGContextStrokePath(context);
  }
}

@end

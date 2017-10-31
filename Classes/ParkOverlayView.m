//
//  ParkOverlayView.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 30.11.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "ParkOverlayView.h"
#import "MenuData.h"
#import "TrackPoint.h" // because of DEBUG_MAP

static TrackPoint *dummyTrackPoint = nil;

@implementation ParkOverlayView
@synthesize coordinate;
@synthesize boundingMapRect;
@synthesize selectedTile;

-(id)initWithRegion:(MKMapRect)mapRect parkId:(NSString *)pId {
  self = [super init];
  dummyTrackPoint = nil;
  boundingMapRect = mapRect;
  coordinate = CLLocationCoordinate2DMake(0, 0);
  parkId = [pId retain];
  availableTiles = [[NSMutableArray alloc] initWithCapacity:50];
  selectedTile = nil;

  double minX = 0.0;
  double maxX = 0.0;
  double minY = 0.0;
  double maxY = 0.0;
  NSError *error = nil;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray *files = [fileManager contentsOfDirectoryAtPath:[[MenuData parkDataPath:parkId] stringByAppendingPathComponent:@"maps"] error:&error];
  if (error != nil) {
    NSLog(@"error to init park overlay view %@", [error localizedDescription]);
  } else if (files != nil) {
    for (NSString *file in files) {
      if ([file hasPrefix:@"tile_"] && [file hasSuffix:@".png"]) {
        NSRange range;
        range.location = 5;
        range.length = [file length] - range.location;
        NSRange range2 = [file rangeOfString:@"_" options:NSCaseInsensitiveSearch range:range];
        if (range2.length == 0) continue;
        range.length = range2.location - range.location;
        ++range2.location;
        range2.length = [file length] - range2.location - 4;
        if (range2.length <= 0) continue;
        double x = [[file substringWithRange:range] doubleValue];
        double y = [[file substringWithRange:range2] doubleValue];
        [availableTiles addObject:[NSNumber numberWithDouble:x]];
        [availableTiles addObject:[NSNumber numberWithDouble:y]];
        if (minX == maxX && minX == 0.0 && minY == maxY && minY == 0.0) {
          minX = maxX = x;
          minY = maxY = y;
        } else {
          if (x < minX) minX = x;
          else if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          else if (y > maxY) maxY = y;
        }
      }
    }
  }
  if (minX != maxX || minY != maxY) boundingMapRect = MKMapRectMake(minX, minY, maxX-minX, maxY-minY);
  NSLog(@"Number of available tiles %d for park %@", (int)[availableTiles count]/2, parkId);
  return self;
}

-(void)dealloc {
  [parkId release];
  parkId = nil;
  [availableTiles release];
  availableTiles = nil;
  [selectedTile release];
  selectedTile = nil;
  [super dealloc];
}

-(NSString *)getTileFileName:(MKMapRect)mapRect {
  MKMapRect rect;
  rect.size.width = rect.size.height = 512.0;
  int l = (int)[availableTiles count]-1;
  for (int i = 0; i < l; i += 2) {
    rect.origin.x = [[availableTiles objectAtIndex:i] doubleValue];
    rect.origin.y = [[availableTiles objectAtIndex:i+1] doubleValue];
    if (MKMapRectContainsRect(mapRect, rect)) {
      return [NSString stringWithFormat:@"tile_%.0f_%.0f.png", rect.origin.x, rect.origin.y];
    }
  }
  return nil;
}

-(NSString *)getTileFileName2:(MKMapRect)mapRect tileRect:(MKMapRect *)tileRect {
  MKMapRect rect;
  rect.size.width = rect.size.height = 512.0;
  int l = (int)[availableTiles count]-1;
  for (int i = 0; i < l; i += 2) {
    rect.origin.x = [[availableTiles objectAtIndex:i] doubleValue];
    rect.origin.y = [[availableTiles objectAtIndex:i+1] doubleValue];
    if (MKMapRectContainsRect(rect, mapRect)) {
      tileRect->origin.x = rect.origin.x;
      tileRect->origin.y = rect.origin.y;
      return [NSString stringWithFormat:@"tile_%.0f_%.0f.png", rect.origin.x, rect.origin.y];
    }
  }
  return nil;
}

-(NSString *)getTileFileNameContainsPoint:(MKMapPoint)mapPoint {
  MKMapRect rect;
  rect.size.width = rect.size.height = 512.0;
  int l = (int)[availableTiles count]-1;
  for (int i = 0; i < l; i += 2) {
    rect.origin.x = [[availableTiles objectAtIndex:i] doubleValue];
    rect.origin.y = [[availableTiles objectAtIndex:i+1] doubleValue];
    if (MKMapRectContainsPoint(rect, mapPoint)) {
      return [NSString stringWithFormat:@"tile_%.0f_%.0f.png", rect.origin.x, rect.origin.y];
    }
  }
  return nil;
}

-(MKMapRect)getRectForTileFileName:(NSString *)fileName {
  MKMapRect rect;
  rect.origin.x = rect.origin.y = rect.size.width = rect.size.height = 0.0;
  if ([fileName hasPrefix:@"tile_"] && [fileName hasSuffix:@".png"]) {
    rect.size.width = rect.size.height = 512.0;
    NSRange range;
    range.location = 5;
    range.length = [fileName length]-5;
    range = [fileName rangeOfString:@"_" options:NSCaseInsensitiveSearch range:range];
    if (range.length > 0) {
      range.length = range.location-5;
      range.location = 5;
      rect.origin.x = [[fileName substringWithRange:range] doubleValue];
      range.location = range.length+6;
      range.length = [fileName length]-range.location;
      rect.origin.y = [[fileName substringWithRange:range] doubleValue];
    }
  }
  return rect;
}

#pragma mark Utility methods

+(BOOL)coordinate:(CLLocationCoordinate2D)coordinate isInside:(MKCoordinateRegion)region {
  if (region.center.latitude+region.span.latitudeDelta < coordinate.latitude || region.center.latitude-region.span.latitudeDelta > coordinate.latitude) return NO;
  return (region.center.longitude+region.span.longitudeDelta >= coordinate.longitude && region.center.longitude-region.span.longitudeDelta <= coordinate.longitude);
}

/**
 * Given a MKMapRect, this returns the zoomLevel based on 
 * the longitude width of the box.
 *
 * This is because the Mercator projection, when tiled,
 * normally operates with 2^zoomLevel tiles (1 big tile for
 * world at zoom 0, 2 tiles at 1, 4 tiles at 2, etc.)
 * and the ratio of the longitude width (out of 360º)
 * can be used to reverse this.
 *
 * This method factors in screen scaling for the iPhone 4:
 * the tile layer will use the *next* zoomLevel. (We are given
 * a screen that is twice as large and zoomed in once more
 * so that the "effective" region shown is the same, but
 * of higher resolution.)
 */
+(int)zoomLevelForMap:(MKMapView *)map {
  float scale = map.bounds.size.width / map.visibleMapRect.size.width;
  scale *= [[UIScreen mainScreen] scale];
  int n = 19;
  while (scale < 1.0f) {
    scale *= 2.0;
    --n;
  }
  return n;
  /*MKMapRect mapRect = map.visibleMapRect;
  MKCoordinateRegion region = MKCoordinateRegionForMapRect(mapRect);
  CGFloat lon_ratio = region.span.longitudeDelta/360.0;
  NSUInteger z = (NSUInteger)(log(1/lon_ratio)/log(2.0)-1.0);
  return z + ([[UIScreen mainScreen] scale] - 1.0);*/
}

/**
 * Similar to above, but uses a MKZoomScale to determine the
 * Mercator zoomLevel. (MKZoomScale is a ratio of screen points to
 * map points.)
 */
+(int)zoomLevelForZoomScale:(MKZoomScale)zoomScale {
  CGFloat realScale = zoomScale / [[UIScreen mainScreen] scale];
  int z = (int)(log(realScale)/log(2.0)+20.0);
  return z + ([[UIScreen mainScreen] scale] - 1.0);
}

/**
 * Shortcut to determine the number of tiles wide *or tall* the
 * world is, at the given zoomLevel. (In the Spherical Mercator
 * projection, the poles are cut off so that the resulting 2D
 * map is "square".)
 */
+(int)worldTileWidthForZoomLevel:(int)zoomLevel {
  return (int)(pow(2,zoomLevel));
}

/**
 * Given a MKMapRect, this reprojects the center of the mapRect
 * into the Mercator projection and calculates the rect's top-left point
 * (so that we can later figure out the tile coordinate).
 *
 * See http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames#Derivation_of_tile_names
 */
+(CGPoint)mercatorTileOriginForMapRect:(MKMapRect)mapRect {
  MKCoordinateRegion region = MKCoordinateRegionForMapRect(mapRect);

  // Convert lat/lon to radians
  CGFloat x = (region.center.longitude) * (M_PI/180.0); // Convert lon to radians
  CGFloat y = (region.center.latitude) * (M_PI/180.0); // Convert lat to radians
  y = log(tan(y)+1.0/cos(y));
  
  // X and Y should actually be the top-left of the rect (the values above represent
  // the center of the rect)
  x = (1.0 + (x/M_PI)) / 2.0;
  y = (1.0 - (y/M_PI)) / 2.0;
  
  return CGPointMake(x, y);
}

#pragma mark MKOverlayView methods

-(BOOL)canDrawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale {
  //int zoomLevel = [ParkOverlayView zoomLevelForZoomScale:zoomScale];
  return YES;//(zoomLevel >= 15 && zoomLevel <= 18);
}

-(void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  /*NSUInteger zoomLevel = [ParkOverlayView zoomLevelForZoomScale:zoomScale];
  //NSLog(@"overlay zoom level %d  (%d)", zoomLevel, [ParkOverlayView zoomLevelForMapRect:mapRect]);
  if (zoomLevel < 15) return;
  NSUInteger zLevel = MIN(zoomLevel, 18);
  //if (zoomLevel > 18) zoomLevel = 18;
  CGPoint mercatorPoint = [ParkOverlayView mercatorTileOriginForMapRect:mapRect];
  NSUInteger zoomFactor = [ParkOverlayView worldTileWidthForZoomLevel:zoomLevel];
  NSUInteger tilex = floor(mercatorPoint.x * zoomFactor);
  NSUInteger tiley = floor(mercatorPoint.y * zoomFactor);
  NSString *filename = [NSString stringWithFormat:@"map_%@_%d_%d_%d_%d_%d.png", parkId, zLevel, mercatorPoint.x, mercatorPoint.y, tilex, tiley];
  NSString *mapPath = [[[MenuData parkDataPath:parkId] stringByAppendingPathComponent:@"maps"] stringByAppendingPathComponent:filename];
  if (zoomLevel == 18 && mapRect.size.width == mapRect.size.height && mapRect.size.width == 1024.0) {
    NSError *error = nil;
   NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *newMapPath = [[[MenuData parkDataPath:parkId] stringByAppendingPathComponent:@"maps"] stringByAppendingPathComponent:newFilename];
    if ([fileManager fileExistsAtPath:mapPath]) [fileManager copyItemAtPath:mapPath toPath:newMapPath error:&error];
    if (error != nil) NSLog(@"Error copy to file %@ (%@)", newMapPath, [error localizedDescription]);
    mapPath = newMapPath;
  }*/
  NSString *mapRootPath = [[MenuData parkDataPath:parkId] stringByAppendingPathComponent:@"maps"];
  int w = (int)mapRect.size.width;
  //NSLog(@"draw rect (%d) %f, %f, %f, %f", w, mapRect.origin.x, mapRect.origin.y, mapRect.size.width, mapRect.size.height);
  MKMapRect rect,rect2;
  rect.size.width = rect.size.height = (w < 512.0)? w : 512.0;
  rect2.size.width = rect2.size.height = 512.0;
  UIGraphicsPushContext(context);
  for (int y = 0; y < w; y += 512) {
    rect2.origin.y = rect.origin.y = mapRect.origin.y + y;
    for (int x = 0; x < w; x += 512) {
      rect2.origin.x = rect.origin.x = mapRect.origin.x + x;
      NSString *tileName = (w < 512.0)? [self getTileFileName2:rect tileRect:&rect2] : [self getTileFileName:rect];
      if (tileName != nil) {
        NSString *mapPath = [mapRootPath stringByAppendingPathComponent:tileName];
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:mapPath];//[UIImage imageWithData:data];
        if (image != nil) {
          CGRect cgRect = (w < 512.0)? [self rectForMapRect:rect2] : [self rectForMapRect:rect];
          //NSLog(@"draw in rect (%d) %f, %f, %f, %f", w, cgRect.origin.x, cgRect.origin.y, cgRect.size.width, cgRect.size.height);
          if (selectedTile != nil && [tileName isEqualToString:selectedTile]) {
            [image drawInRect:cgRect blendMode:kCGBlendModeDarken alpha:0.7];
          } else {
            [image drawInRect:cgRect];
          }
          [image release];
#ifdef DEBUG_MAP
          if (selectedTile == nil) {
            UILabel *label = [[UILabel alloc] initWithFrame:cgRect];
            label.textColor = [UIColor blackColor];
            label.font = [UIFont systemFontOfSize:14.0f];
            label.text = tileName;
            [label drawTextInRect:cgRect];
            [label release];
            /*char* text	= (char *)[tileName cStringUsingEncoding:NSASCIIStringEncoding];
             NSLog(@"text: %s", text);
             CGContextSelectFont(context, "Arial", 24, kCGEncodingMacRoman);
             CGContextSetTextDrawingMode(context, kCGTextFill);
             CGContextSetRGBFillColor(context, 0.0f, 0.0f, 0.0f, 1.0f);
             CGContextShowTextAtPoint(context, 8.0f, 24.0f, text, strlen(text));*/
          }
#endif
        } else {
          NSLog(@"Missing tile for %@", tileName);
        }
      }
    }
  }
  UIGraphicsPopContext();

  //UIImage *image = [UIImage imageNamed:@"map1.png"];  
  //This should do the trick, but is doesn't.. maybe a problem with the "context"?
  //CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
  //CGContextTranslateCTM(context, 0, image.size.height);
  //CGContextScaleCTM(context, 1.0, -1.0);
  
  //CGRect overallCGRect = [self rectForMapRect:self.boundingMapRect];
  //CGContextDrawImage(context, overallCGRect, image.CGImage);
  /*FIX:
   UIImage *image = [UIImage imageNamed:@"map1.png"];
   MKMapRect theMapRect = [self.overlay boundingMapRect];
   CGRect theRect = [self rectForMapRect:theMapRect];
   
   UIGraphicsPushContext(context);
   [image drawInRect:theRect blendMode:kCGBlendModeNormal alpha:1.0];
   UIGraphicsPopContext();
   // Have you tried subclassing MKOverlayView instead of MKPolygonView?
   */

  //CGRect overlayRect = [self rectForMapRect:boundingMapRect];
  /*CGRect overlayRect = CGRectMake(0, 0, image.size.width, image.size.height);
  
  UIGraphicsPushContext(context);
  [image drawInRect:overlayRect blendMode:kCGBlendModeNormal alpha:1.0];
  UIGraphicsPopContext(); */
  [pool release];
}

@end

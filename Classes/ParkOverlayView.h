//
//  ParkOverlayView.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 30.11.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface ParkOverlayView : MKOverlayView<MKOverlay> {
  CLLocationCoordinate2D coordinate;
  MKMapRect boundingMapRect;
  NSString *parkId;
  NSMutableArray *availableTiles;
  NSString *selectedTile;
}

-(id)initWithRegion:(MKMapRect)mapRect parkId:(NSString *)pId;

-(NSString *)getTileFileName:(MKMapRect)mapRect;
-(NSString *)getTileFileName2:(MKMapRect)mapRect tileRect:(MKMapRect *)tileRect;
-(NSString *)getTileFileNameContainsPoint:(MKMapPoint)mapPoint;
-(MKMapRect)getRectForTileFileName:(NSString *)fileName;

+(BOOL)coordinate:(CLLocationCoordinate2D)coordinate isInside:(MKCoordinateRegion)region;

+(int)zoomLevelForMap:(MKMapView *)map;
+(int)zoomLevelForZoomScale:(MKZoomScale)zoomScale;
+(int)worldTileWidthForZoomLevel:(int)zoomLevel;
+(CGPoint)mercatorTileOriginForMapRect:(MKMapRect)mapRect;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) MKMapRect boundingMapRect;
@property (nonatomic, retain) NSString *selectedTile;

@end

//
//  RouteView.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 21.10.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

// annotation view that is created for display of a route. 
@interface RouteView : MKAnnotationView {
@private
  MKMapView *mapView;
  int selectedTrackPointIndex;
  BOOL viewDirection;
}

-(id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic, retain) MKMapView *mapView;
@property int selectedTrackPointIndex;
@property BOOL viewDirection;

@end

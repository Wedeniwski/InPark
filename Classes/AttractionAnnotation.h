//
//  AttractionAnnotation.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 22.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface AttractionAnnotation : MKAnnotationView {
}

-(void)updateImage:(float)zoomScale;

@end

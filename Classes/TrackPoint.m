//
//  TrackPoint.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 18.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "TrackPoint.h"
//#import <MapKit/MapKit.h>
#include <math.h>

// Returns the distance between two points (given the latitude/longitude of those points) using Haversine formula.
double distanceHaversine(double lat1, double lon1, double lat2, double lon2) {
  if (lat1 == lat2 && lon1 == lon2) return 0.0;
  const double DEG2RAD = 0.017453292519943;
  const double rlat1 = lat1*DEG2RAD;
  const double rlat2 = lat2*DEG2RAD;
  return acos(sin(rlat1)*sin(rlat2) + cos(rlat1)*cos(rlat2)*cos((lon1-lon2)*DEG2RAD)) * 6371007.2;
}

// Returns the distance between two points (given the latitude/longitude of those points) using Vincenty inverse formula for ellipsoids.
double distanceVincenty(double lat1, double lon1, double lat2, double lon2) {
  const double DEG2RAD = 0.017453292519943;
  const double a = 6378137;
  const double b = 6356752.314245;
  const double f = 1/298.257223563;  // WGS-84 ellipsoid params
  double L = (lon2-lon1)*DEG2RAD;
  double U1 = atan((1-f) * tan(lat1*DEG2RAD));
  double U2 = atan((1-f) * tan(lat2*DEG2RAD));
  double sinU1 = sin(U1);
  double cosU1 = cos(U1);
  double sinU2 = sin(U2);
  double cosU2 = cos(U2);
  double lambda = L;
  for (int i = 100; i >= 0; --i) {
    double sinLambda = sin(lambda);
    double cosLambda = cos(lambda);
    double sinSigma = sqrt((cosU2*sinLambda) * (cosU2*sinLambda) + 
                           (cosU1*sinU2-sinU1*cosU2*cosLambda) * (cosU1*sinU2-sinU1*cosU2*cosLambda));
    if (sinSigma == 0) return 0;  // co-incident points
    double cosSigma = sinU1*sinU2 + cosU1*cosU2*cosLambda;
    double sigma = atan2(sinSigma, cosSigma);
    double sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
    double cosSqAlpha = 1 - sinAlpha*sinAlpha;
    double cos2SigmaM = cosSigma - 2*sinU1*sinU2/cosSqAlpha;
    if (isnan(cos2SigmaM)) cos2SigmaM = 0;  // equatorial line: cosSqAlpha=0 (§6)
    double C = f/16*cosSqAlpha*(4+f*(4-3*cosSqAlpha));
    double lambdaP = lambda;
    lambda = L + (1-C) * f * sinAlpha * (sigma + C*sinSigma*(cos2SigmaM+C*cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)));
    if (abs(lambda-lambdaP) <= 1e-12) {
      double uSq = cosSqAlpha * (a*a - b*b) / (b*b);
      double A = 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)));
      double B = uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)));
      double deltaSigma = B*sinSigma*(cos2SigmaM+B/4*(cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)-
                                                      B/6*cos2SigmaM*(-3+4*sinSigma*sinSigma)*(-3+4*cos2SigmaM*cos2SigmaM)));
      return b*A*(sigma-deltaSigma);
    }
  }
  return distanceHaversine(lat1, lon1, lat2, lon2);
}

double distance(double lat1, double lon1, double lat2, double lon2) {
  return distanceHaversine(lat1, lon1, lat2, lon2);
}

@implementation TrackPoint

-(id)initWithLatitude:(double)lat longitude:(double)lon {
  self = [super init];
  if (self != nil) {
    latitude = (int)(lat*1000000);
    longitude = (int)(lon*1000000);
  }
  return self;
}

-(id)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self != nil) {
    if ([coder containsValueForKey:@"LATITUDE_INT"]) {
      latitude = [coder decodeIntForKey:@"LATITUDE_INT"];
      longitude = [coder decodeIntForKey:@"LONGITUDE_INT"];
    } else {
      latitude = (int)([coder decodeDoubleForKey:@"LATITUDE"]*1000000);
      longitude = (int)([coder decodeDoubleForKey:@"LONGITUDE"]*1000000);
    }
  }
  return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeInt:latitude forKey:@"LATITUDE_INT"];
  [coder encodeInt:longitude forKey:@"LONGITUDE_INT"];
}

-(BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[TrackPoint class]]) return NO;
  TrackPoint *trackPoint = (TrackPoint *)object;
  return (latitude == trackPoint.latitudeInt && longitude == trackPoint.longitudeInt);
}

+(double)distanceFrom:(TrackPoint *)fromTrackPoint to:(TrackPoint *)toTrackPoint {
  return distanceHaversine(fromTrackPoint.latitude, fromTrackPoint.longitude, toTrackPoint.latitude, toTrackPoint.longitude);
}

-(double)distanceTo:(TrackPoint *)trackPoint {
  return distanceHaversine(latitude/1000000.0, longitude/1000000.0, trackPoint.latitude, trackPoint.longitude);
  //return distanceVincenty(a.latitude, a.longitude, b.latitude, b.latitude);
  //CLLocationCoordinate2D location = { a.latitude, a.longitude };
  /*CLLocation *a = [[CLLocation alloc] initWithLatitude:a.latitude longitude:a.longitude];
   CLLocation *b = [[CLLocation alloc] initWithLatitude:b.latitude longitude:b.longitude];
   CLLocationDistance distance = [a distanceFromLocation:b];
   [a release];
   [b release];
   return distance;*/
}

-(void)addLatitude:(double)latitudeDelta {
  latitude += (int)(latitudeDelta*1000000);
}

-(void)addLongitude:(double)longitudeDelta {
  longitude += (int)(longitudeDelta*1000000);
}

-(NSString *)toString {
  return [NSString stringWithFormat:@"    <trkpt lat=\"%.6f\" lon=\"%.6f\">\n    </trkpt>", latitude/1000000.0, longitude/1000000.0];
}

-(double)latitude {
  return latitude/1000000.0;
}

-(double)longitude {
  return longitude/1000000.0;
}

-(int)latitudeInt {
  return latitude;
}

-(int)longitudeInt {
  return longitude;
}

@end

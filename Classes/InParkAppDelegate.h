//
//  InParkAppDelegate.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 26.11.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iRate.h"

@interface InParkAppDelegate : NSObject <UIApplicationDelegate, iRateDelegate> {
  IBOutlet UIViewController *viewController;
  UIWindow *window;
}

@property (retain, nonatomic) UIViewController *viewController;
@property (retain, nonatomic) UIWindow *window;

@end


//
//  CoverFlowItemView.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.10.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsynchronousImageView.h"

@interface CoverFlowItemView : UIView {
	AsynchronousImageView *imageView;
}

-(BOOL)isEqual:(id)object;

-(void)setImagePath:(NSString *)path;

@property (readonly, nonatomic) UIImage *image;
@property (readonly, nonatomic) AsynchronousImageView *imageView;

@end

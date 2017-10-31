//
//  IPadHelper.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 12.12.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IPadHelper : NSObject {
}

+(BOOL)isIPad;
+(NSString *)addIPadSuffixWhenOnIPad:(NSString *)resourceName;
  
@end

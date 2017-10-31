//
//  MenuData.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 17.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MenuData : NSObject {
}

+(int)binarySearch:(NSString *)key inside:(NSArray *)array;

+(void)ensurePathStructure:(NSArray *)path toBase:(NSString *)basePath;
+(NSString *)libraryCachePath;
+(NSString *)applicationSupportPath;
+(NSString *)documentPath;
+(NSString *)oldestDataPath;
+(NSString *)oldDataPath;
+(NSString *)newDataPath;
+(NSString *)dataPath;
+(NSString *)parkDataPath:(NSString *)parkId;
+(NSString *)relativeParkDataPath:(NSString *)parkId toBase:(NSString *)basePath;

+(NSDictionary *)getRootOfFile:(NSString *)filename languagePath:(NSString *)languagePath;
+(NSDictionary *)getRootOfFile:(NSString *)filename;
+(NSDictionary *)getRootOfData:(NSString *)filename languagePath:(NSString *)languagePath;
+(NSDictionary *)getRootOfData:(NSString *)filename;
+(NSArray *)getRootKey:(NSString *)key languagePath:(NSString *)languagePath;
+(NSArray *)getRootKey:(NSString *)key;
+(NSString *)objectForKey:(NSString *)key at:(NSDictionary *)d;

+(NSArray *)getParkIds;
+(NSDictionary *)getParkNames;
+(NSString *)getParkName:(NSString *)parkId cache:(BOOL)cache;
+(NSDictionary *)getParkDetails:(NSString *)parkId cache:(BOOL)cache;
+(NSDictionary *)getAllAttractionDetails:(NSString *)parkId cache:(BOOL)cache;
+(NSDictionary *)getAttractionDetails:(NSString *)parkId attractionId:(NSString *)attractionId cache:(BOOL)cache;

+(NSString*)stringByHyphenating:(NSString *)string;

@end

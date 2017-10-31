//
//  ImageData.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 28.10.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageProperty.h"

@interface ImageData : NSObject {
}

+(NSString *)oldestAdditionalImagesDataPath;
+(NSString *)oldAdditionalImagesDataPath;
+(NSString *)newAdditionalImagesDataPath;
+(NSString *)additionalImagesDataPath;
+(NSString *)userImagesDataPath;
+(void)validateImageProperiesForParkId:(NSString *)parkId attractionIds:(NSArray *)attractionIds data:(NSDictionary *)data;
+(void)deleteParkId:(NSString *)parkId;
+(void)deleteParkId:(NSString *)parkId attractionId:(NSString *)attractionId localData:(NSDictionary *)localData;
+(void)deleteParkId:(NSString *)parkId attractionId:(NSString *)attractionId fileName:(const char *)fileName localData:(NSDictionary *)localData;
+(void)deleteUserImage:(NSString *)imagePath;
+(NSDictionary *)localData;
+(BOOL)save:(NSDictionary *)data;
+(NSDictionary *)availableDataForParkId:(NSString *)parkId reload:(BOOL)reload;
+(void)clearCacheOfAvailableData;
+(void)updateLocalDataWithAvailableDataOfParkId:(NSString *)parkId;
+(void)updateLocalDataWithAvailableDataOfParkId:(NSString *)parkId attractionId:(NSString *)attractionId;
+(BOOL)isPathAvailableOfParkId:(NSString *)parkId;
+(NSSet *)allParkIdsWithAvailableChanges;
+(BOOL)changesAvailableForParkId:(NSString *)parkId;
+(int)availableChangesOfParkId:(NSString *)parkId betweenLocalData:(NSDictionary *)localData andAvailableData:(NSDictionary *)availableData resultingChanges:(NSMutableArray *)changes numberOfChangingImages:(int *)numberOfChangingImages;
+(int)availableChangesOfParkId:(NSString *)parkId attractionId:(NSString *)attractionId betweenLocalData:(NSDictionary *)localData andAvailableData:(NSDictionary *)availableData resultingChanges:(NSMutableArray *)changes numberOfChangingImages:(int *)numberOfChangingImages;
+(NSDictionary *)availableChangesSizeImagePathesByKindOfForParkId:(NSString *)parkId;
+(NSArray *)allImagePathesForParkId:(NSString *)parkId attractionId:(NSString *)attractionId data:(NSDictionary *)data;
+(NSArray *)imageProperiesForParkId:(NSString *)parkId attractionId:(NSString *)attractionId data:(NSDictionary *)data;
+(NSArray *)userImagePathesForParkId:(NSString *)parkId attractionId:(NSString *)attractionId;
+(NSArray *)getImagePropertiesForParkId:(NSString *)parkId attractionId:(NSString *)attractionId insideAvailableData:(NSDictionary *)availableData;
+(NSString *)getAttractionIdForImage:(NSString *)imagePath atParkId:(NSString *)parkId insideAvailableData:(NSDictionary *)availableData;

+(BOOL)isRetinaDisplay;
+(UIImage *)rescaleImage:(UIImage *)image toSize:(CGSize)size;
+(UIImage *)makeBackgroundImage:(UIImage*)myImage;

@end

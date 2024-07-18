//
//  EntProjectFile+CoreDataProperties.h
//  AppGuard
//
//  Created by 周和生 on 15/10/27.
//  Copyright © 2015年 GoodDay. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntProjectFile.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntProjectFile (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *extension;
@property (nullable, nonatomic, retain) NSString *filename;
@property (nullable, nonatomic, retain) NSNumber *modified;
@property (nullable, nonatomic, retain) NSString *relativepath;
@property (nullable, nonatomic, retain) NSNumber *selected;
@property (nullable, nonatomic, retain) NSString *path;
@property (nullable, nonatomic, retain) NSString *folder;

@end

NS_ASSUME_NONNULL_END

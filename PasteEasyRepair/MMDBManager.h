//
//  MMDBManager.h
//  Paste
//
//  Created by gyh on 2020/12/9.
//

@import Foundation;


#define XM_GCD_MAIN(__BLOCK__) dispatch_async(dispatch_get_main_queue(), __BLOCK__)

#define XM_GCD_ASYNC(__BLOCK__) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), __BLOCK__)

#define XM_OPERATION_MAIN(__BLOCK__) [[NSOperationQueue mainQueue] addOperationWithBlock:__BLOCK__]

#define XM_GCD_AFTER(TIME, __BLOCK__) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), __BLOCK__);

#define WEAK_SELF   __weak typeof(self)weakSelf = self;
#define STRONG_SELF   __strong typeof(weakSelf)strongSelf = weakSelf;

#define BLOCK_EXEC(block, ...) if (block) { block(__VA_ARGS__); };



NS_ASSUME_NONNULL_BEGIN

@interface MMDBManager : NSObject

+ (instancetype)sharedManager;

- (BOOL)deleteNewestData;

@end

NS_ASSUME_NONNULL_END

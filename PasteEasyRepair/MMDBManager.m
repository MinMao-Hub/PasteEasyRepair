//
//  MMDBManager.m
//  Paste
//
//  Created by gyh on 2020/12/9.
//

#import "MMDBManager.h"
#import "FMDB.h"

//数据库名称
static NSString *const kDatabaseName = @"pastedata.thumb";
//表名 - 记录
static NSString *const kTableNamePaste = @"T_PASTE_SNAPSHOT";
//表名 - 记录 - 关联数据
static NSString *const kTableNamePasteConnect = @"T_PASTE_SNAPSHOT_CONNECT";
//表名 - 分类
static NSString *const kTableNamePinboard = @"T_PASTE_PINBOARD";
//表名 - 应用信息
static NSString *const kTableNameAppInfo = @"T_PASTE_APPINFO";
//表名 - 已过滤应用信息
static NSString *const kTableNameExcludeAppInfo = @"T_PASTE_EXCLUDEAPP";

//新建分类Key前缀
static NSString *const kCategoryKeyPer = @"M_PINBOARD_";

@interface MMDBManager ()

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

@end

@implementation MMDBManager

+ (instancetype)sharedManager {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init  {
    self = [super init];
    if (self) {
        NSString *dbPath = [self createAndReturnDBPath];
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        [self createAllTable];
    }
    return self;
}

//删除最新一条数据以及其关联数据
//DELETE FROM table_name ORDER BY id DESC LIMIT 1
- (BOOL)deleteNewestData {
    NSInteger firstId = [self queryFirstSnapshotId];
    NSLog(@"===>>> %@", @(firstId));
    NSString *execSql = [NSString stringWithFormat: @"DELETE FROM %@ ORDER BY TIMESTAMP DESC LIMIT 1", kTableNamePaste];
    NSString *execSql1 = [NSString stringWithFormat: @"DELETE FROM %@ WHERE CONNECTID = ?", kTableNamePasteConnect];
    __block BOOL result;
    [_dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        result = [db executeUpdate:execSql];
        result = [db executeUpdate:execSql1 withArgumentsInArray:@[@(firstId)]];
    }];
    return result;
}


/// 查询所有数据
- (NSArray<NSDictionary *> *)queryAllSnapshots {
    //外连接 - 把应用信息链接进来
    NSString *execSql1 = [NSString stringWithFormat: @"SELECT P.*, A.ICON, A.LOCALNAME FROM %@ P INNER JOIN %@ A ON P.APPLICATIONINFO = A.APPLICATIONINFO AND P.PIN LIKE ( ? ) ORDER BY P.TIMESTAMP DESC", kTableNamePaste, kTableNameAppInfo];
    NSMutableArray *array = [NSMutableArray array];
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *result = [db executeQuery:execSql1];
        while (result.next) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [dic setObject:@([result intForColumnIndex:0]) forKey:@"ID"];
            [dic setObject:[result stringForColumnIndex:1] forKey:@"title"];
            [dic setObject:@([result intForColumnIndex:2]) forKey:@"type"];
            [dic setObject:[result stringForColumnIndex:3] forKey:@"sourceType"];
            [dic setObject:[result stringForColumnIndex:4] forKey:@"md5"];
            [dic setObject:@([result doubleForColumnIndex:5]) forKey:@"timestamp"];
            [dic setObject:[result stringForColumnIndex:6] forKey:@"intro"];
            [dic setObject:@([result intForColumnIndex:7]) forKey:@"appId"];
            [dic setObject:[result dataForColumnIndex:8] forKey:@"data"];
            [dic setObject:[result dataForColumnIndex:9] forKey:@"preview"];
            [dic setObject:[result stringForColumnIndex:10] forKey:@"filePaths"];
            [dic setObject:@([result intForColumnIndex:11]) forKey:@"textLength"];
            [dic setObject:[result stringForColumnIndex:12] forKey:@"imageSize"];
            [dic setObject:[result stringForColumnIndex:13] forKey:@"pin"];
            [dic setObject:[result stringForColumnIndex:14] forKey:@"searchKey"];
            [dic setObject:[result dataForColumnIndex:15] forKey:@"reservedB"];
            [dic setObject:[result dataForColumnIndex:18] forKey:@"appIcon"];
            [dic setObject:[result stringForColumnIndex:19] forKey:@"appName"];
            [array addObject:dic];
        }
        [result close];
    }];
    
    NSLog(@"pastedata: %@", array);
    
    return [array copy];
}

/// 根据关键字 - 查询数据
- (NSArray<NSDictionary *> *)querySnapshotsWithKey:(NSString *)key {
    NSString *condition = @"SELECT P.*, A.ICON, A.LOCALNAME "
                    @"FROM %@ P "
                    @"INNER JOIN %@ A "
                    @"ON P.APPLICATIONINFO = A.APPLICATIONINFO "
                    @"AND (P.INTRO LIKE ( ? ) OR P.TITLE LIKE ( ? ) OR P.SEARCH LIKE ( ? ) OR A.LOCALNAME LIKE ( ? )) "
                    @"ORDER BY P.TIMESTAMP "
                    @"DESC";
    NSString *sql = [NSString stringWithFormat:condition, kTableNamePaste, kTableNameAppInfo];
    NSMutableArray *array = [NSMutableArray array];
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *result = [db executeQuery:sql withArgumentsInArray:@[
            [NSString stringWithFormat:@"%%%@%%",key],
            [NSString stringWithFormat:@"%%%@%%",key],
            [NSString stringWithFormat:@"%%[%@],%%",key],
            [NSString stringWithFormat:@"%%%@%%",key]]];
        while (result.next) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [dic setObject:@([result intForColumnIndex:0]) forKey:@"ID"];
            [dic setObject:[result stringForColumnIndex:1] forKey:@"title"];
            [dic setObject:@([result intForColumnIndex:2]) forKey:@"type"];
            [dic setObject:[result stringForColumnIndex:3] forKey:@"sourceType"];
            [dic setObject:[result stringForColumnIndex:4] forKey:@"md5"];
            [dic setObject:@([result doubleForColumnIndex:5]) forKey:@"timestamp"];
            [dic setObject:[result stringForColumnIndex:6] forKey:@"intro"];
            [dic setObject:@([result intForColumnIndex:7]) forKey:@"appId"];
            [dic setObject:[result dataForColumnIndex:8] forKey:@"data"];
            [dic setObject:[result dataForColumnIndex:9] forKey:@"preview"];
            [dic setObject:[result stringForColumnIndex:10] forKey:@"filePaths"];
            [dic setObject:@([result intForColumnIndex:11]) forKey:@"textLength"];
            [dic setObject:[result stringForColumnIndex:12] forKey:@"imageSize"];
            [dic setObject:[result stringForColumnIndex:13] forKey:@"pin"];
            [dic setObject:[result stringForColumnIndex:14] forKey:@"searchKey"];
            [dic setObject:[result dataForColumnIndex:15] forKey:@"reservedB"];
            [dic setObject:[result dataForColumnIndex:18] forKey:@"appIcon"];
            [dic setObject:[result stringForColumnIndex:19] forKey:@"appName"];
            [array addObject:dic];
        }
        [result close];
    }];
    
    return [array copy];
}

//查询最新第一条的id
- (NSInteger)queryFirstSnapshotId {
    NSString *execSql1 = [NSString stringWithFormat: @"SELECT * FROM %@ ORDER BY TIMESTAMP DESC LIMIT 1", kTableNamePaste];
    __block NSInteger snapshotId = 0;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *result = [db executeQuery:execSql1];
        while (result.next) {
            snapshotId = [result intForColumnIndex:0];
        }
    }];
    return snapshotId;
}

//创建&返回db路径
- (NSString *)createAndReturnDBPath {
    //先判断Document文件夹下面有没有数据库文件
    NSString *dbFilePath = @"~/Library/Containers/com.minmao.paste/Data/Documents/PasteEasy/pastedata.thumb";
    return  [dbFilePath stringByExpandingTildeInPath];
}

//创建 —— 表
- (void)createAllTable {
    NSString *execSqlPaste = [NSString stringWithFormat:
                         @"CREATE TABLE IF NOT EXISTS %@ (ID INTEGER PRIMARY KEY AUTOINCREMENT, TITLE TEXT, TYPE INTEGER, SOURCETYPE TEXT, MD5 TEXT, TIMESTAMP NUMBER, INTRO TEXT, APPLICATIONINFO INTEGER, DATA BLOB, PREVIEW BLOB, FILEURLS TEXT, TEXTLENGTH INTEGER, IMAGESIZE TEXT, PIN TEXT, SEARCH TEXT, RESERVEDB BLOB, RESERVEDT TEXT, RESERVEDI INTEGER)", kTableNamePaste];
    NSString *execSqlPasteConnect = [NSString stringWithFormat:
                         @"CREATE TABLE IF NOT EXISTS %@ (ID INTEGER PRIMARY KEY AUTOINCREMENT, CONNECTID INTEGER, TYPE TEXT, DATA BLOB)", kTableNamePasteConnect];
    NSString *execSqlPinboard = [NSString stringWithFormat:
                         @"CREATE TABLE IF NOT EXISTS %@ (ID TEXT PRIMARY KEY UNIQUE NOT NULL, TITLE TEXT, TIMESTAMP NUMBER)", kTableNamePinboard];
    NSString *execSqlAppInfo = [NSString stringWithFormat:
                         @"CREATE TABLE IF NOT EXISTS %@ (APPLICATIONINFO INTEGER PRIMARY KEY AUTOINCREMENT, LOCALNAME TEXT, BUNDLEID TEXT UNIQUE NOT NULL, ICON BLOB, TIMESTAMP NUMBER)", kTableNameAppInfo];
    NSString *execSqlExcludeAppInfo = [NSString stringWithFormat:
                         @"CREATE TABLE IF NOT EXISTS %@ (APPLICATIONINFO INTEGER PRIMARY KEY AUTOINCREMENT, BUNDLEID TEXT UNIQUE)", kTableNameExcludeAppInfo];
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        if ([db executeStatements:[NSString stringWithFormat:@"%@;%@;%@;%@;%@",execSqlPaste, execSqlPasteConnect, execSqlPinboard, execSqlAppInfo, execSqlExcludeAppInfo]]) {
            NSLog(@"创建表成功");
        } else {
            NSLog(@"创建表失败");
        }
    }];
}

@end

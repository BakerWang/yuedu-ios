//
//  DowloadViewController.m
//  YueduFM
//
//  Created by StarNet on 9/26/15.
//  Copyright (c) 2015 StarNet. All rights reserved.
//

#import "DowloadViewController.h"
#import "DownloadTableViewCell.h"

static int const kCountPerTime = 20;

typedef NS_ENUM(int, DownloadType) {
    DownloadTypeDone = 0,
    DownloadTypeDoing,
};

static NSString* const kDownloadCellIdentifier = @"kDownloadCellIdentifier";

@interface DowloadViewController () {
    UISegmentedControl* _segmentedControl;
}

@end

@implementation DowloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavigationBar];
    
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem itemWithImage:[UIImage imageNamed:@"icon_nav_delete.png"] action:^{
        
        if ([self isDownloadTypeDone]) {
            UIAlertView* alert = [UIAlertView bk_alertViewWithTitle:nil message:@"您确定清空已下载的文章?"];
            [alert bk_addButtonWithTitle:@"清空" handler:^{
                [SRV(ArticleService) deleteAllDownloaded:^{
                    [self load];
                    [self showWithSuccessedMessage:@"清空成功"];
                }];
            }];
            
            [alert bk_addButtonWithTitle:@"取消" handler:nil];
            [alert show];
        } else {
            UIAlertView* alert = [UIAlertView bk_alertViewWithTitle:nil message:@"您确定清空所有任务?"];
            [alert bk_addButtonWithTitle:@"清空" handler:^{
                [SRV(DownloadService) deleteAllTask:^{
                    [self load];
                    [self showWithSuccessedMessage:@"清空成功"];
                }];
            }];
            
            [alert bk_addButtonWithTitle:@"取消" handler:nil];
            [alert show];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadSeriviceDidChangedNotification:) name:DownloadSeriviceDidChangedNotification object:nil];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"DownloadTableViewCell" bundle:nil] forCellReuseIdentifier:kDownloadCellIdentifier];
    
    [SRV(DownloadService) state:^(BOOL downloading) {
        _segmentedControl.selectedSegmentIndex = downloading?DownloadTypeDoing:DownloadTypeDone;
        [self load];
    }];
}

- (void)downloadSeriviceDidChangedNotification:(NSNotification* )notification {
    [self load];
}

- (BOOL)isDownloadTypeDone {
    return _segmentedControl.selectedSegmentIndex == DownloadTypeDone;
}

- (void)load {
    if ([self isDownloadTypeDone]) {
        [SRV(ArticleService) listDownloaded:kCountPerTime completion:^(NSArray *array) {
            [self reloadData:array];
        }];
    } else {
        [SRV(DownloadService) list:^(NSArray *tasks) {
            [self reloadData:tasks];
        }];
    }
}

- (void)addFooter {
    self.tableView.footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        if ([self isDownloadTypeDone]) {
            [SRV(ArticleService) listDownloaded:(int)[self.tableData count]+kCountPerTime completion:^(NSArray *array) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self reloadData:array];
                    [self.tableView.footer endRefreshing];
                    
                    if ([self.tableData count] == [array count]) {
                        self.tableView.footer = nil;
                    }
                });
            }];
        }
    }];
}

- (void)setupNavigationBar {
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"已下载", @"正在下载"]];
    [_segmentedControl bk_addEventHandler:^(id sender) {
        [self load];
    } forControlEvents:UIControlEventValueChanged];
    _segmentedControl.selectedSegmentIndex = 0;
    self.navigationItem.titleView = _segmentedControl;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UINib* )nibForExpandCell {
    return [UINib nibWithNibName:@"DownloadActionTableViewCell" bundle:nil];
}

- (UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isDownloadTypeDone]) {
        return [super cellForRowAtIndexPath:indexPath];
    } else {
        NSURLSessionTask* task = self.tableData[indexPath.row];
        DownloadTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:kDownloadCellIdentifier forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.task = task;        
        return cell;
    }
}

@end

//
//  ViewController.m
//  PasteEasyRepair
//
//  Created by guoyonghong on 2023/7/10.
//

#import "ViewController.h"
#import "MMDBManager.h"
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
- (IBAction)onClickRepair:(id)sender {
    //获取数据库文件
    [[MMDBManager sharedManager] deleteNewestData];
}

- (IBAction)onClickContact:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/MinMao-Hub/PasteEasy/tree/main/cn"]];
}

@end

//
//  RPSendRedPacketViewController.m
//  RedpacketLib
//
//  Created by 都基鹏 on 16/8/1.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#import "RPSendRedPacketViewController.h"
#import "RPSendRedPacketCountCellItem.h"
#import "RPSendRedPacketMemberCellItem.h"
#import "RPSendRedPacketChangeCellItem.h"
#import "RPSendRedPacketDescribeCellItem.h"
#import "RPSendRedPacketCertainCellItem.h"
#import "RPSendRedPacketItem.h"
#import "RPSendRedPacketBaseTableViewCellProtocol.h"
#import "RedpacketColorStore.h"
#import "RPRedpacketSetting.h"
#import "SearchMemberViewController.h"
#import "RPSendRedPacketAutoKeyboardHandle.h"
#import "RedpacketErrorView.h"
#import "UIView+YZHExtension.h"
#import "RPRedpacketSendControl.h"
#import "RPRedpacketBridge.h"
#import "RPRedpacketSetting.h"

@interface RPSendRedPacketViewController ()<RPSendRedPacketBaseTableViewCellProtocol,SearchMemberViewDelegate>

@property (nonatomic,strong) RPBaseCellItem                    * certainCellItem;
@property (nonatomic,strong) RPBaseCellItem                    * changeCellItem;
@property (nonatomic,strong) RPSendRedPacketItem               * rawItem;
@property (nonatomic,strong) UILabel                           * warnPromptLabel;
@property (nonatomic,strong) RPSendRedPacketAutoKeyboardHandle * autoKeyboardHandle;
@property (nonatomic,weak  ) RedpacketErrorView                * errorView;

@end

@implementation RPSendRedPacketViewController

- (void)dealloc
{
    [RPRedpacketSendControl releaseSendControl];
}

#pragma mark - init
- (instancetype)initWithControllerType:(RPSendRedPacketViewControllerType)type {
    self = [super init];
    
    if (self) {
        self.rawItem = [RPSendRedPacketItem new];
        
        RPSendRedPacketMemberCellItem * memberCellItem = [RPSendRedPacketMemberCellItem new];
        memberCellItem.rawItem = self.rawItem;
        [self.dataSource addObject:memberCellItem];
        
        RPSendRedPacketCountCellItem * countCellItem = [RPSendRedPacketCountCellItem new];
        countCellItem.rawItem = self.rawItem;
        [self.dataSource addObject:countCellItem];
        
        RPSendRedPacketChangeCellItem * changeCellItem = [RPSendRedPacketChangeCellItem new];
        self.changeCellItem = changeCellItem;
        changeCellItem.rawItem = self.rawItem;
        [self.dataSource addObject:changeCellItem];
        
        RPSendRedPacketDescribeCellItem * describeCellItem = [RPSendRedPacketDescribeCellItem new];
        describeCellItem.rawItem = self.rawItem;
        [self.dataSource addObject:describeCellItem];
        
        RPSendRedPacketCertainCellItem * certainCellItem = [RPSendRedPacketCertainCellItem new];
        certainCellItem.rawItem = self.rawItem;
        self.certainCellItem = certainCellItem;
        [self.dataSource addObject:certainCellItem];
        
        switch (type) {
            case RPSendRedPacketViewControllerSingle: {
                [self.dataSource removeObject:memberCellItem];
                [self.dataSource removeObject:countCellItem];
                self.titleLable.text = @"发红包";
                self.rawItem.redPacketType = RPRedpacketTypeSingle;
                break;
            }
            case RPSendRedPacketViewControllerGroup: {
                [self.dataSource removeObject:memberCellItem];
                self.titleLable.text = @"发群红包";
                self.rawItem.redPacketType = RPRedpacketTypeGroupRand;
                break;
            }
            case RPSendRedPacketViewControllerMember:
                self.titleLable.text = @"发群红包";
                self.rawItem.redPacketType = RPRedpacketTypeGroupRand;
                break;
                
            default:
                break;
        }
    }
    
    return self;
}

- (void)setMemberCount:(NSInteger)memberCount {
    self.rawItem.memberCount = memberCount;
}

- (void)setConversationInfo:(RPUserInfo *)conversationInfo
{
    _conversationInfo = conversationInfo;
    self.rawItem.conversationInfo = self.conversationInfo;
}

#pragma mark - ViewDidLoad

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [RedpacketColorStore rp_backGroundGrayColor];
    self.tableView.contentInset = UIEdgeInsetsMake(14, 0, 0, 0);
    [self configViewStyle];
    [self resgistDescribeLabe];
    [self configNetworking];
}

- (void)configNetworking {
    
    [self.view rp_showHudWaitingView:YZHPromptTypeWating];
    rpWeakSelf;
    //  获取发红包时所需的各种限额
   [RPRedpacketSetting asyncRequestRedpacketSettings:^(NSError *error) {
       [weakSelf.view rp_removeHudInManaual];
       if (!error) {
           weakSelf.subLable.text = [NSString stringWithFormat:@"%@红包服务",[RPRedpacketSetting shareInstance].redpacketOrgName];
           [weakSelf showErrorView:NO];
       } else {
           [weakSelf showErrorView:YES];
           [weakSelf.view rp_showHudErrorView:error.localizedDescription];
       }
   }];
    
}

#pragma mark - ViewStyle
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
    self.navigationController.navigationBar.barStyle       = UIBarStyleBlack;
    
    [self setNavgationBarBackgroundColor:[RedpacketColorStore rp_textColorRed]
                              titleColor:[RedpacketColorStore rp_textcolorYellow]
                         leftButtonTitle:@"关闭"
                        rightButtonTitle:@""];
    
    self.autoKeyboardHandle = [[RPSendRedPacketAutoKeyboardHandle alloc] init];
}

- (void)configViewStyle {
    self.view.backgroundColor = [RedpacketColorStore rp_backGroundColor];
    self.navigationController.navigationBar.tintColor      = [RedpacketColorStore rp_textcolorYellow];
    self.navigationController.navigationBar.backIndicatorImage = rpRedpacketBundleImage(@"navigationbar_back");
    self.navigationController.navigationBar.backIndicatorTransitionMaskImage = rpRedpacketBundleImage(@"navigationbar_back");
}

- (void)clickButtonLeft {
    [RPRedpacketSendControl releaseSendControl];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRawItem:(RPBaseCellItem *)cellItem {
    
    if ([cellItem isKindOfClass:[RPSendRedPacketMemberCellItem class]]) {
        
        SearchMemberViewController * searchController = [[SearchMemberViewController alloc]init];
        searchController.delegate = self;
        [self.navigationController pushViewController:searchController animated:YES];
        
    }
    
}

#pragma mark - CellDelegate
- (void)didChangePacketInputMoney {
    
    if (!self.certainCellItem.cellIndexPath) return;
    
    [self.certainCellItem.tableViewCell setCellItem:self.certainCellItem];
    [self showWarmPromtLableWith:self.rawItem.warningTittle];
}

- (void)didChangePacketCount {
    if (!self.certainCellItem.cellIndexPath) return;
    
    [self.certainCellItem.tableViewCell setCellItem:self.certainCellItem];
    [self showWarmPromtLableWith:self.rawItem.warningTittle];
    [self.changeCellItem.tableViewCell tableViewCellCustomAction];
}

- (void)didChangePacketPlayType {
    [self.tableView reloadData];
    [self showWarmPromtLableWith:self.rawItem.warningTittle];
}

- (void)didSendRedPacket {
    
    rpWeakSelf;
    RPRedpacketSendControl *sendControl = [RPRedpacketSendControl currentControl];
    sendControl.hostViewController = self.hostController;
    
    [sendControl payMoney:[NSString stringWithFormat:@"%.2f",self.rawItem.totalMoney.floatValue/100.0f]
         withMessageModel:self.rawItem.messageModel
             inController:self andSuccessBlock:^(id object) {
                 
        RPRedpacketModel *redpacketModel = (RPRedpacketModel *)object;
        weakSelf.sendRedPacketBlock(redpacketModel);
        [weakSelf dismissViewControllerAnimated:YES completion:^{
            
        }];
                 
    }];
    
}

#pragma mark -SearchMemberViewDelegate

- (void)receiverInfos:(NSArray<RPUserInfo *> *)userInfos {
    self.rawItem.redPacketType = userInfos?RPRedpacketTypeGoupMember:self.rawItem.cacheRedPacketType;
    self.rawItem.memberList = userInfos;
    [self showWarmPromtLableWith:self.rawItem.warningTittle];
    [self.tableView reloadData];
}

- (void)getGroupMemberListCompletionHandle:(void (^)(NSArray<RPUserInfo *> *))completionHandle {
    
    if (completionHandle && self.fetchBlock) {
        
        self.fetchBlock(completionHandle);
        
    }
    
}

#pragma mark - View Store

- (UILabel *)warnPromptLabel {
    if (!_warnPromptLabel) {
        _warnPromptLabel = [[UILabel alloc]init];
        _warnPromptLabel.backgroundColor = [UIColor colorWithRed:161/255.0 green:23/255.0 blue:16/255.0 alpha:1.0];
        _warnPromptLabel.textColor = [UIColor colorWithRed:240/255.0 green:220/255.0 blue:74/255.0 alpha:1];
        _warnPromptLabel.textAlignment = NSTextAlignmentCenter;
        _warnPromptLabel.font = [UIFont systemFontOfSize:14.0f];
        _warnPromptLabel.frame = CGRectMake(0, -25, [UIScreen mainScreen].bounds.size.width,25);
        _warnPromptLabel.tag = 0;
        [self.view addSubview:_warnPromptLabel];
    }
    return _warnPromptLabel;
}

- (void)showWarmPromtLableWith:(NSString *)content {
    
    self.warnPromptLabel.text = content;
    
    if (content.length && self.warnPromptLabel.tag != 1) {
        
        self.warnPromptLabel.tag = 1;
        
        [UIView animateWithDuration:0.5 animations:^{
            
            self.warnPromptLabel.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width,25);
            
        }];
        
    }else if (!content.length && self.warnPromptLabel.tag) {
        
        [UIView animateWithDuration:0.5 animations:^{
            
            self.warnPromptLabel.frame = CGRectMake(0, -25, [UIScreen mainScreen].bounds.size.width,25);
            
        } completion:^(BOOL finished) {
            
            self.warnPromptLabel.tag = 0;
            
        }];
        
    }
}

- (RedpacketErrorView *)errorView {
    if (_errorView == nil) {
        RedpacketErrorView * errorView = [[RedpacketErrorView alloc]init];
        errorView.tag = 0;
        errorView.frame = CGRectMake(0, RP_SCREENHEIGHT, RP_SCREENWIDTH, RP_SCREENHEIGHT);
        
        rpWeakSelf;
        errorView.buttonClickBlock = ^(){
            
            [weakSelf configNetworking];
            
        };
        
        [self.view addSubview:errorView];
        _errorView = errorView;
    }
    
    return _errorView;
}

- (void)showErrorView:(BOOL)show {
    rpWeakSelf;
    CGFloat top;
    NSInteger tag;
    if (show && self.errorView.tag != 1) {
        
        tag = 1;
        top = 0;
        
    }else if (!show && self.errorView.tag == 1){
        
        tag = 0;
        top = RP_SCREENHEIGHT;
        
    }else{
        
        return;
        
    }
    
    weakSelf.errorView.rp_top = top;
    weakSelf.errorView.tag = tag;
}

- (void)resgistDescribeLabe {
    UILabel * lable = [UILabel new];
    lable.text = @"未领取的红包，将于24小时后发起退款";
    lable.textAlignment = NSTextAlignmentCenter;
    lable.textColor = [RedpacketColorStore colorWithHexString:@"9e9e9e" alpha:1.0];
    lable.font = [UIFont systemFontOfSize:12];
    lable.frame = CGRectMake(0, self.view.rp_height - 28 -64, self.view.rp_width, 14);
    [self.view addSubview:lable];
}

@end

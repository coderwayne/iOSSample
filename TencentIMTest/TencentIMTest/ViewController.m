//
//  ViewController.m
//  TencentIMTest
//
//  Created by 胡晓伟 on 2020/4/13.
//  Copyright © 2020 ofweek. All rights reserved.
//

#import "ViewController.h"
#import <ImSDK/ImSDK.h>
#import "GenerateTestUserSig.h"
#import "Common.h"
#import <TIMCallback.h>

@interface ViewController () <TIMConnListener, TIMUserStatusListener, TIMRefreshListener, TIMMessageReceiptListener, TIMMessageRevokeListener,
TIMUploadProgressListener, TIMGroupEventListener, TIMFriendshipListener, TIMMessageListener>

@property (weak, nonatomic) IBOutlet UITextField *txtUserName;
@property (weak, nonatomic) IBOutlet UITextView *txtInfo;

@property (copy, nonatomic) NSString *userSig;
@property (weak, nonatomic) IBOutlet UITextField *txtSendUser;
@property (weak, nonatomic) IBOutlet UITextField *txtC2CMsg;

@end

@implementation ViewController

- (IBAction)tempButtonClicked:(id)sender {
    /**
    *  1.3 创建聊天室
    *
    *  快速创建聊天室，创建者默认加入群组，无需显式指定，群组类型形态请参考官网文档 [群组形态介绍](https://cloud.tencent.com/document/product/269/1502#.E7.BE.A4.E7.BB.84.E5.BD.A2.E6.80.81.E4.BB.8B.E7.BB.8D)
    *
    *  @param members   群成员，NSString* 数组
    *  @param groupName 群名
    *  @param succ      成功回调 groupId
    *  @param fail      失败回调
    *
    *  @return 0：成功；1：失败
    */
    
    //每次创建的聊天室groupId不一样，证明groupName只是一个标识，创建了多个叫这个名字的聊天室。
    [[TIMGroupManager sharedInstance] createChatRoomGroup:nil groupName:@"wayne's first chatroom" succ:^(NSString *groupId) {
        [self appendInfoText:[NSString stringWithFormat:@"创建聊天室成功，groupId：%@", groupId]];
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"创建聊天室失败：：%d->%@", code, msg]];
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
     _txtInfo.layoutManager.allowsNonContiguousLayout = NO;
}

// step 1 : 根据用户名生成userSig
- (IBAction)generateUserSig:(id)sender {
    _userSig = [GenerateTestUserSig genTestUserSig:_txtUserName.text];
    [self appendInfoText:[NSString stringWithFormat:@"生成sig成功：%@", _userSig]];
}

// step 2 : 初始化TIMManager
- (IBAction)initTIMManager:(id)sender {
    //全局配置信息
    TIMSdkConfig *sdkConfig = [[TIMSdkConfig alloc] init];
    //用户标识接入 SDK 的应用 ID，必填
    sdkConfig.sdkAppId = 1400343975;
    //禁止在控制台打印 log
    sdkConfig.disableLogPrint = NO;
    //本地写 log 文件的等级，默认 DEBUG 等级
    sdkConfig.logLevel = TIM_LOG_DEBUG;
    //回调给 logFunc 函数的 log 等级，默认 DEBUG 等级
    sdkConfig.logFuncLevel = TIM_LOG_DEBUG;
    //log 监听函数
    sdkConfig.logFunc = ^(TIMLogLevel lvl, NSString *msg) {
//        NSString *info = [NSString stringWithFormat:@"监听：%@", [NSString stringWithFormat:@"log func action, LogLevel:%ld, msg:%@", (long)lvl, msg]];
//        [self appendInfoText:info];
    };
    //网络监听器，监听网络连接成功失败的状态
    sdkConfig.connListener = self;
    //消息数据库路径，不设置时为默认路径
    //    sdkConfig.dbPath = @"";
    //log 文件路径，不设置时为默认路径，可以通过 TIMManager -> getLogPath 获取 log 路径
    //    sdkConfig.logPath = @"";
    
    
    TIMManager * manager = [TIMManager sharedInstance];
//    @return 0：成功；1：失败，config 为 nil
    
    if([manager initSdk:sdkConfig] == 0) {
        [self appendInfoText:@"sdk初始化成功"];
        // 设置接收消息的回调
        [manager addMessageListener:self];
    }
}

// step 3 : 设置用户参数
- (IBAction)setUserConfig:(id)sender {
    TIMUserConfig *userConfig = [[TIMUserConfig alloc] init];

    // 禁用本地存储（AVChatRoom,BChatRoom 消息数量很大，出于程序性能的考虑，默认不存本地）
    NSLog(@"%d", userConfig.disableStorage);
    
    // 是否开启多终端同步未读提醒，这个选项主要影响多终端登录时的未读消息提醒逻辑。
    // YES：只有当一个终端调用 setReadMessage() 将消息标记为已读，另一个终端再登录时才不会收到未读提醒；
    // NO：消息一旦被一个终端接收，另一个终端都不会再次提醒。同理，卸载 App 再安装也无法再次收到这些未读消息。
    NSLog(@"%d", userConfig.disableAutoReport);
    

    // 是否开启被阅回执。
    // YES：接收者查看消息（setReadMessage）后，消息的发送者会收到 TIMMessageReceiptListener 的回调提醒；
    // NO: 不开启被阅回执，默认不开启。
    NSLog(@"%d", userConfig.enableReadReceipt);
    
    userConfig.userStatusListener = self;
    
    // 会话刷新监听器，用于监听会话的刷新
    //@property(nonatomic,weak) id<TIMRefreshListener> refreshListener;
    userConfig.refreshListener = self;
    
    // 消息已读回执监听器，用于监听消息已读回执，enableReadReceipt 字段需要设置为 YES
    userConfig.enableReadReceipt = YES;
    userConfig.messageReceiptListener = self;

    // 消息撤回监听器，用于监听会话中的消息撤回通知
    userConfig.messageRevokeListener = self;

    // 文件上传进度监听器，发送语音，图片，视频，文件消息的时候需要先上传对应文件到服务器，这里可以监听上传进度
    userConfig.uploadProgressListener = self;

    // 群组事件通知监听器
    userConfig.groupEventListener = self;
    
    // 关系链数据本地缓存监听器
    //@property(nonatomic,weak) id<TIMFriendshipListener> friendshipListener;
    userConfig.friendshipListener = self;

    // 设置默认拉取的群组资料，如果想要拉取自定义字段，要通过即时通信 IM 控制台 > 功能配置 > 群维度自定义字段配置对应的 "自定义字段" 和用户操作权限，控制台配置之后5分钟后才会生效。
    //  @property(nonatomic,strong) TIMGroupInfoOption * groupInfoOpt;
    
    // 设置默认拉取的群成员资料，如果想要拉取自定义字段，要通过即时通信 IM 控制台 > 功能配置 > 群成员维度自定义字段配置对应的 "自定义字段" 和用户操作权限，控制台配置之后5分钟后才会生效。
    //  @property(nonatomic,strong) TIMGroupMemberInfoOption * groupMemberInfoOpt;
    
    // 关系链参数
    //  @property(nonatomic,strong) TIMFriendProfileOption * friendProfileOpt;

}

// step 4 : 登录
- (IBAction)loginAction:(id)sender {
    TIMLoginParam * login_param = [[TIMLoginParam alloc ]init];
    // identifier 为用户名
    login_param.identifier = _txtUserName.text;
    //userSig 为用户登录凭证
    login_param.userSig = _userSig;
    //appidAt3rd App 用户使用 OAuth 授权体系分配的 Appid，在私有帐号情况下，填写与 SDKAppID 一样
    login_param.appidAt3rd = @"1400343975";
    [[TIMManager sharedInstance] login: login_param succ:^(){
        [self appendInfoText:@"登录成功"];
        
    } fail:^(int code, NSString * err) {
        [self appendInfoText:[NSString stringWithFormat:@"登录失败：：%d->%@", code, err]];
    }];
}

// 注销
- (IBAction)logoutAction:(id)sender {
    [[TIMManager sharedInstance] logout:^() {
        [self appendInfoText:@"注销登录成功"];
    } fail:^(int code, NSString * err) {
        [self appendInfoText:[NSString stringWithFormat:@"注销登录失败: code=%d err=%@", code, err]];
    }];
}

// 获取用户/判断登录
- (IBAction)getLoginUser:(id)sender {
    TIMManager * manager = [TIMManager sharedInstance];
    NSLog(@"当前登录用户：%@", manager.getLoginUser);
}

// 发送文本消息(单聊)
- (IBAction)sendC2CTextMsg:(id)sender {
    TIMTextElem *textElem = [[TIMTextElem alloc] init];
    [textElem setText:_txtC2CMsg.text];
    
    TIMMessage *msg = [[TIMMessage alloc] init];
    [msg addElem:textElem];
    
    TIMConversation *c2c_conversation = [[TIMManager sharedInstance] getConversation:TIM_C2C receiver:_txtSendUser.text];
    [c2c_conversation sendMessage:msg succ:^{
        [self appendInfoText:@"消息发送成功"];
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"消息发送失败 code=%d err=%@", code, msg]];
    }];
}

#pragma TIMConnListener 消息回调

- (void)onNewMessage:(NSArray *)msgs {
    [self appendInfoText:@"收到新消息"];
    
    for (TIMMessage *msg in msgs) {
        TIMElem *elem = [msg getElem:0];
        [self appendInfoText:[NSString stringWithFormat:@"消息的类型是：%@", [elem class]]];
        
        if([elem isKindOfClass:[TIMTextElem class]]) {
            TIMTextElem *textElem = (TIMTextElem *)elem;
            [self appendInfoText:[NSString stringWithFormat:@"收到文本消息: %@", textElem.text]];
        }
        else if([elem isKindOfClass:[TIMGroupSystemElem class]]) {
            TIMGroupSystemElem *groupSystemElem = (TIMGroupSystemElem *)elem;
            [self appendInfoText:[NSString stringWithFormat:@"收到group系统消息: %@", groupSystemElem]];
        }
        
//        TIMElem *elem = [msg getElem:0];
//        if ([elem isKindOfClass:[TIMCustomElem class]]) {
//            TIMCustomElem *custom = (TIMCustomElem *)elem;
//            NSDictionary *param = [TCUtil jsonData2Dictionary:[custom data]];
//            if (param != nil && [param[@"version"] integerValue] == 2) {
//                [[VideoCallManager shareInstance] onNewVideoCallMessage:msg];
//            }
//        }
    }
}

///**
// *  消息回调
// */
//@protocol TIMMessageListener <NSObject>
//@optional
///**
// *  新消息回调通知
// *
// *  @param msgs 新消息列表，TIMMessage 类型数组
// */
//- (void)onNewMessage:(NSArray*)msgs;
//@end

#pragma TIMConnListener 网络事件
- (void)onConnSucc {
    [self appendInfoText:@"IM服务器连接成功"];
}

- (void)onConnFailed:(int)code err:(NSString *)err {
    // code 错误码：具体参见错误码表
    [self appendInfoText:[NSString stringWithFormat:@"IM服务器连接失败: code=%d, err=%@", code, err]];
}

- (void)onDisconnect:(int)code err:(NSString *)err {
    // code 错误码：具体参见错误码表
    [self appendInfoText:[NSString stringWithFormat:@"IM服务器连接断开: code=%d, err=%@", code, err]];
}

#pragma TIMUserStatusListener 用户在线状态通知
- (void)onForceOffline {
    [self appendInfoText:@"被踢下线通知"];
}

- (void)onReConnFailed:(int)code err:(NSString *)err {
    [self appendInfoText:[NSString stringWithFormat:@"断线重连失败: code=%d, err=%@", code, err]];
}

- (void)onUserSigExpired {
    [self appendInfoText:@"用户登录的userSig过期（用户需要重新获取userSig后登录）"];
}

#pragma TIMRefreshListener 页面刷新接口 (如有需要未读计数刷新,会话列表刷新等)
- (void)onRefresh {
    [self appendInfoText:@"刷新会话"];
}

- (void)onRefreshConversations:(NSArray<TIMConversation *> *)conversations {
    [self appendInfoText:@"刷新部分会话，参数为会话（TIMConversation*）列表"];
}

#pragma TIMMessageReceiptListener 收到了已读回执
- (void)onRecvMessageReceipts:(NSArray *)receipts {
    [self appendInfoText:@"收到了已读回执，参数为已读回执（TIMMessageReceipt*）列表"];
}

#pragma TIMMessageReceiptListener 消息撤回通知
- (void)onRevokeMessage:(TIMMessageLocator *)locator {
    [self appendInfoText:@"收到了消息撤回通知，参数为被撤回消息的标识(TIMMessageLocator*)locator"];
}

#pragma TIMMessageReceiptListener 上传进度回调
- (void)onUploadProgressCallback:(TIMMessage *)msg elemidx:(uint32_t)elemidx taskid:(uint32_t)taskid progress:(uint32_t)progress {
    [self appendInfoText:@"收到了上传进度回调，参数为msg(正在上传的消息), elemidx(正在上传的elem的索引), taskid(任务id), progress(上传进度)"];
}

#pragma TIMGroupEventListener 群事件通知回调
- (void)onGroupTipsEvent:(TIMGroupTipsElem *)elem {
    [self appendInfoText:@"收到了群tips回调，参数为群tips消息(TIMGroupTipsElem*)elem"];
}

#pragma TIMFriendshipListener 好友代理事件回调
- (void)onAddFriends:(NSArray *)users {
    [self appendInfoText:@"收到了添加好友通知，参数为数组，数组项为users（NSString*）"];
}

- (void)onDelFriends:(NSArray *)identifiers {
    [self appendInfoText:@"收到了删除好友通知，参数为数组，数组项为用户id列表（NSString*）"];
}

- (void)onFriendProfileUpdate:(NSArray<TIMSNSChangeInfo *> *)profiles {
    [self appendInfoText:@"收到了好友资料更新通知，参数为数组，数组项为资料列表（TIMSNSChangeInfo *）"];
}

- (void)onAddFriendReqs:(NSArray<TIMFriendPendencyInfo *> *)reqs {
    [self appendInfoText:@"收到了好友申请通知，参数为数组，数组项为好友申请者id列表（TIMFriendPendencyInfo *）"];
}

- (void)appendInfoText:(NSString *)text {
    NSDate *datenow = [NSDate date];
    NSString *timeStamp = [NSString stringWithFormat:@"%ld", (long)([datenow timeIntervalSince1970]*1000)];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_txtInfo.text = [self->_txtInfo.text stringByAppendingString:[NSString stringWithFormat:@"%@ %@\n", [Common timeWithTimeStamp:timeStamp], text]];
        [self->_txtInfo scrollRangeToVisible:NSMakeRange(self->_txtInfo.text.length, 1)];
    });
}

- (IBAction)clearTextView:(id)sender {
    _txtInfo.text = @"";
}
@end

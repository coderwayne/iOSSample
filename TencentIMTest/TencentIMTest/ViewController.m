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
@property (weak, nonatomic) IBOutlet UITextField *txtGroupId;
@property (weak, nonatomic) IBOutlet UITextField *txtGroupMsg;

@end

@implementation ViewController

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
            [self appendInfoText:[NSString stringWithFormat:@"收到group系统消息: %ld", (long)groupSystemElem.type]];
            
            switch (groupSystemElem.type) {
                case TIM_GROUP_SYSTEM_ADD_GROUP_REQUEST_TYPE:
                    [self appendInfoText:[NSString stringWithFormat:@"有人申请加群，申请人是:%@，群组ID:%@，申请理由:%@", groupSystemElem.user, groupSystemElem.group, groupSystemElem.msg]];
                    break;
                case TIM_GROUP_SYSTEM_ADD_GROUP_ACCEPT_TYPE:
                    //触发时机：当管理员同意加群请求时，申请人会收到同意入群的消息
                    [self appendInfoText:[NSString stringWithFormat:@"你的申请加群通过了，审核管理员是:%@，群组ID:%@，同意的理由:%@", groupSystemElem.user, groupSystemElem.group, groupSystemElem.msg]];
                    break;
                case TIM_GROUP_SYSTEM_ADD_GROUP_REFUSE_TYPE:
                    //触发时机：当管理员拒绝加群请求时，申请人会收到拒绝入群的消息
                    [self appendInfoText:[NSString stringWithFormat:@"你的申请加群被拒绝了，审核管理员是:%@，群组ID:%@，拒绝的理由:%@", groupSystemElem.user, groupSystemElem.group, groupSystemElem.msg]];
                    break;
                case TIM_GROUP_SYSTEM_KICK_OFF_FROM_GROUP_TYPE:
                    // 这里所谓的“踢出”，实际执行的是删除用户(deleteGroupMemberWithReason)
                    [self appendInfoText:[NSString stringWithFormat:@"你被踢出了群组，操作的管理员是:%@，群组ID:%@", groupSystemElem.user, groupSystemElem.group]];
                    break;
                case TIM_GROUP_SYSTEM_DELETE_GROUP_TYPE:
                    // 群被解散
                    [self appendInfoText:[NSString stringWithFormat:@"群被解散了，操作的管理员是:%@，群组ID:%@", groupSystemElem.user, groupSystemElem.group]];
                    break;
                case TIM_GROUP_SYSTEM_QUIT_GROUP_TYPE:
                    // 主动退群
                    [self appendInfoText:[NSString stringWithFormat:@"你主动退群了，你是:%@，群组ID:%@", groupSystemElem.user, groupSystemElem.group]];
                    break;
                case TIM_GROUP_SYSTEM_GRANT_ADMIN_TYPE:
                    // 被设置成了管理员
                    [self appendInfoText:[NSString stringWithFormat:@"你被设置成管理员，操作人:%@，群组ID:%@", groupSystemElem.user, groupSystemElem.group]];
                    break;
                case TIM_GROUP_SYSTEM_CANCEL_ADMIN_TYPE:
                    // 被取消了管理员
                    [self appendInfoText:[NSString stringWithFormat:@"你被取消了管理员，操作人:%@，群组ID:%@", groupSystemElem.user, groupSystemElem.group]];
                    break;
                case TIM_GROUP_SYSTEM_REVOKE_GROUP_TYPE:
                    // 当群组被系统回收时，全员可收到群组被回收消息。
                    [self appendInfoText:[NSString stringWithFormat:@"你加入的这个群组%@被系统回收了", groupSystemElem.group]];
                    break;
                default:
                    NSLog(@"ignore type");
                    break;
            }
        }
        else if([elem isKindOfClass:[TIMGroupTipsElem class]]) {
            TIMGroupTipsElem *groupTipsElem = (TIMGroupTipsElem *)elem;
            [self appendInfoText:[NSString stringWithFormat:@"收到group tips消息: %@", groupTipsElem]];
            
            switch (groupTipsElem.type) {
                case TIM_GROUP_TIPS_TYPE_INVITE:
                    [self appendInfoText:[NSString stringWithFormat:@"有用户进入群，该用户是:%@，群名:%@, 入群的用户列表:%@", groupTipsElem.opUser, groupTipsElem.groupName, groupTipsElem.userList]];
                    break;
                case TIM_GROUP_TIPS_TYPE_QUIT_GRP:
                    [self appendInfoText:[NSString stringWithFormat:@"有用户退出群，该用户是:%@，群名:%@", groupTipsElem.opUser, groupTipsElem.groupName]];
                    break;
                case TIM_GROUP_TIPS_TYPE_KICKED:
                    [self appendInfoText:[NSString stringWithFormat:@"用户被踢出群组，该用户是:%@，群名:%@", groupTipsElem.opUser, groupTipsElem.groupName]];
                    break;
                case TIM_GROUP_TIPS_TYPE_SET_ADMIN:
                    [self appendInfoText:[NSString stringWithFormat:@"有用户被设置管理员，该用户是:%@，群名:%@, 被设置管理员身份的用户列表:%@", groupTipsElem.opUser, groupTipsElem.groupName, groupTipsElem.userList]];
                    break;
                case TIM_GROUP_TIPS_TYPE_CANCEL_ADMIN:
                    [self appendInfoText:[NSString stringWithFormat:@"有用户被取消管理员，该用户是:%@，群名:%@, 被取消管理员身份的用户列表:%@", groupTipsElem.opUser, groupTipsElem.groupName, groupTipsElem.userList]];
                    break;
                case TIM_GROUP_TIPS_TYPE_INFO_CHANGE:
                    [self appendInfoText:[NSString stringWithFormat:@"群资料变更，操作用户是:%@，群名:%@, 群变更的具体资料信息:%@", groupTipsElem.opUser, groupTipsElem.groupName, groupTipsElem.groupChangeList]];
                    break;
                default:
                    NSLog(@"ignore type");
                    break;
            }
        }

        else if([elem isKindOfClass:[TIMCustomElem class]]) {
            TIMCustomElem *customElem = (TIMCustomElem *)elem;
            NSData *receiveData = customElem.data;
            NSString *jsonString = [[NSString alloc] initWithData:receiveData encoding:NSUTF8StringEncoding];
            [self appendInfoText:[NSString stringWithFormat:@"json string is %@", jsonString]];
        }
        
    }
}

// 获取群资料
- (IBAction)getGroupInfo:(id)sender {
//    @param groups 群组 ID 列表
//    *  @param succ 成功回调，不包含 selfInfo 信息
//    *  @param fail 失败回调
//    *
    NSMutableArray *groups = [[NSMutableArray alloc] init];
    [groups addObject:_txtGroupId.text];
    
    [[TIMGroupManager sharedInstance] getGroupInfo:groups succ:^(NSArray *groupList) {
        int i = 0;
        // 列表为 TIMGroupInfo，结构体只包含 group|groupName|groupType|faceUrl|allShutup|selfInfo 信息
        for (TIMGroupInfo *groupInfo in groupList) {
            i++;
            [self appendInfoText:[NSString stringWithFormat:@"查询到的第%d个群组：", i]];
            [self appendInfoText:[NSString stringWithFormat:@"群组ID：%@", groupInfo.group]];
            [self appendInfoText:[NSString stringWithFormat:@"入群类型：%ld", (long)groupInfo.addOpt]];
            [self appendInfoText:[NSString stringWithFormat:@"群名称：%@", groupInfo.groupName]];
            [self appendInfoText:[NSString stringWithFormat:@"群类型：%@", groupInfo.groupType]];
            [self appendInfoText:[NSString stringWithFormat:@"群头像：%@", groupInfo.faceURL]];
            [self appendInfoText:[NSString stringWithFormat:@"是否全体禁言：%d", groupInfo.allShutup]];
            // 成功回调，不包含 selfInfo 信息
            [self appendInfoText:[NSString stringWithFormat:@"群组中的本人信息：%@", groupInfo.selfInfo]];
        }
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"获取群资料失败 code=%d err=%@", code, msg]];
    }];
}

// 获取我在群里的资料
- (IBAction)getGroupSelfInfo:(id)sender {
    [[TIMGroupManager sharedInstance] getGroupSelfInfo:_txtGroupId.text succ:^(TIMGroupMemberInfo *selfInfo) {

        [self appendInfoText:[NSString stringWithFormat:@"被操作成员：%@", selfInfo.member]];
        [self appendInfoText:[NSString stringWithFormat:@"群名片：%@", selfInfo.nameCard]];
        [self appendInfoText:[NSString stringWithFormat:@"加入群组时间：%ld", selfInfo.joinTime]];
        // 0 -- TIM_GROUP_MEMBER_UNDEFINED -- 未定义(没有获取该字段)
        // 200 -- TIM_GROUP_MEMBER_ROLE_MEMBER -- 群成员
        // 300 -- TIM_GROUP_MEMBER_ROLE_ADMIN -- 群管理员
        // 400 -- TIM_GROUP_MEMBER_ROLE_SUPER -- 群主
        [self appendInfoText:[NSString stringWithFormat:@"成员类型：%ld", selfInfo.role]];
        [self appendInfoText:[NSString stringWithFormat:@"禁言时间（剩余秒数）：%u", selfInfo.silentUntil]];
        // 自定义字段集合,key 是 NSString*类型,value 是 NSData*类型
        [self appendInfoText:[NSString stringWithFormat:@"自定义字段集合：%@", selfInfo.customInfo]];
        
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"获取我在群里的资料失败 code=%d err=%@", code, msg]];
    }];
}

// 邀请入群消息
- (IBAction)inviteUserToGroup:(id)sender {
//    即时通信IM 公开群创建成功后，群主邀请人入群报错10007
//
//    Public群默认配置是：除了App管理员，其他人都能邀请加人，但是这个配置是可以通过修改群组形态修改。
    
    
    // 触发时机：当有用户被邀请群时，该用户会收到邀请入群消息，可展示给用户，由用户决定是否同意入群，如果同意，调用 accept 方法，拒绝调用 refuse 方法。
    [[TIMGroupManager sharedInstance] inviteGroupMember:_txtGroupId.text members:[NSArray arrayWithObjects:@"hxw", @"wdl", nil] succ:^(NSArray *members) {
        for (TIMGroupMemberResult * result in members) {
            [self appendInfoText:[NSString stringWithFormat:@"邀请用户入群成功 user %@ status %ld", result.member, (long)result.status]];
        }
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"邀请用户入群失败 code=%d err=%@", code, msg]];
    }];
}

// 修改用户角色
- (IBAction)changeUserRole:(id)sender {

    [[TIMGroupManager sharedInstance] modifyGroupMemberInfoSetRole:_txtGroupId.text user:_txtSendUser.text role:TIM_GROUP_MEMBER_ROLE_ADMIN succ:^{
        [self appendInfoText:[NSString stringWithFormat:@"修改用户角色成功，%@现在是管理员", self->_txtSendUser.text]];
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"修改用户角色失败 code=%d err=%@", code, msg]];
    }];
}

// 获取群组未决列表
- (IBAction)getPendencyFromServer:(id)sender {
    TIMGroupPendencyOption *option = [[TIMGroupPendencyOption alloc] init];
    option.timestamp = 0; //拉取的起始时间 0：拉取最新的
    option.numPerPage = 10; //每页的数量，最大值为 10，设置超过 10，也最多只能拉回 10 条
    
    [[TIMGroupManager sharedInstance] getPendencyFromServer:option succ:^(TIMGroupPendencyMeta *meta, NSArray<TIMGroupPendencyItem *> *pendencies) {
        [self appendInfoText:@"获取群组未决列表成功"];
        [self appendInfoText:[NSString stringWithFormat:@"下一次拉取的起始时间戳:%llu, 已读时间戳大小:%llu, 未决未读数:%d", meta.nextStartTime, meta.readTimeSeq, meta.unReadCnt]];
        
        int i = 0;
        for (TIMGroupPendencyItem *pendencyItem in pendencies) {
            i++;
            [self appendInfoText:[NSString stringWithFormat:@"第%d条未决申请：", i]];
            [self appendInfoText:[NSString stringWithFormat:@"相关群组id：%@", pendencyItem.groupId]];
            [self appendInfoText:[NSString stringWithFormat:@"请求者id(请求加群:请求者，邀请加群:邀请人)：%@", pendencyItem.fromUser]];
            [self appendInfoText:[NSString stringWithFormat:@"判决者id(请求加群:0，邀请加群:被邀请人)：%@", pendencyItem.toUser]];
            [self appendInfoText:[NSString stringWithFormat:@"未决添加时间：%llu", pendencyItem.addTime]];
            // TIM_GROUP_PENDENCY_GET_TYPE_JOIN(申请入群), TIM_GROUP_PENDENCY_GET_TYPE_INVITE(邀请入群)
            [self appendInfoText:[NSString stringWithFormat:@"未决请求类型：%ld", (long)pendencyItem.getType]];
            // TIM_GROUP_PENDENCY_HANDLE_STATUS_UNHANDLED(未处理)
            // TIM_GROUP_PENDENCY_HANDLE_STATUS_OTHER_HANDLED(被他人处理)
            // TIM_GROUP_PENDENCY_HANDLE_STATUS_OPERATOR_HANDLED(被用户处理)
            [self appendInfoText:[NSString stringWithFormat:@"已决标志：%ld", pendencyItem.handleStatus]];
            // TIM_GROUP_PENDENCY_HANDLE_RESULT_REFUSE(拒绝申请)，TIM_GROUP_PENDENCY_HANDLE_RESULT_AGREE(同意申请)
            [self appendInfoText:[NSString stringWithFormat:@"已决结果：%ld", pendencyItem.handleResult]];
            [self appendInfoText:[NSString stringWithFormat:@"申请或邀请附加信息：%@", pendencyItem.requestMsg]];
            [self appendInfoText:[NSString stringWithFormat:@"审批信息：同意或拒绝信息：%@", pendencyItem.handledMsg]];
            [self appendInfoText:[NSString stringWithFormat:@"用户自己的id：%@", pendencyItem.selfIdentifier]];

            [pendencyItem accept:@"这是同意理由" succ:^{
                [self appendInfoText:@"操作审核通过成功"];
            } fail:^(int code, NSString *msg) {
                [self appendInfoText:[NSString stringWithFormat:@"操作审核通过失败 code=%d err=%@", code, msg]];
            }];
            
//            [pendencyItem refuse:@"这是拒绝理由" succ:^{
//                [self appendInfoText:@"操作审核拒绝成功"];
//            } fail:^(int code, NSString *msg) {
//                [self appendInfoText:[NSString stringWithFormat:@"操作审核拒绝失败 code=%d err=%@", code, msg]];
//            }];

        }
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"获取群组未决列表失败 code=%d err=%@", code, msg]];
    }];
}

// 设置某人禁言
- (IBAction)modifyUserShutup:(id)sender {
    [[TIMGroupManager sharedInstance] modifyGroupMemberInfoSetSilence:_txtGroupId.text user:@"hxw" stime:30 succ:^{
        [self appendInfoText:@"设置禁言成功"];
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"设置禁言失败 code=%d err=%@", code, msg]];
    }];
}

// 设置全员禁言
- (IBAction)modifyGroupAllShutup:(id)sender {
    int returnValue = [[TIMGroupManager sharedInstance] modifyGroupAllShutup:_txtGroupId.text shutup:NO succ:^{
        [self appendInfoText:@"设置禁言成功"];
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"设置禁言失败 code=%d err=%@", code, msg]];
    }];
    
    [self appendInfoText:[NSString stringWithFormat:@"设置禁言返回值：%d", returnValue]];
}

// 转让群组
- (IBAction)modifyGroupOwner:(id)sender {
    [[TIMGroupManager sharedInstance] modifyGroupOwner:_txtGroupId.text user:@"wdl" succ:^{
        [self appendInfoText:@"转让群成功"];
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"转让群失败 code=%d err=%@", code, msg]];
    }];
}

// 解散群组
- (IBAction)deleteGroup:(id)sender {
    [[TIMGroupManager sharedInstance] deleteGroup:_txtGroupId.text succ:^{
        [self appendInfoText:@"解散群成功"];
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"解散群失败 code=%d err=%@", code, msg]];
    }];
}

- (IBAction)tempButtonClicked:(id)sender {
    NSString *bodyString =  @"{\"name\": \"John Doe\", \"age\": 18, \"address\": {\"country\" : \"china\", \"zip-code\": \"10000\"}}";
    NSDictionary *dic = @{@"msg_id":@"1001", @"stamp":@"200420180112", @"body":bodyString};

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:kNilOptions error:nil];
    
    TIMCustomElem *customElem = [[TIMCustomElem alloc] init];
    customElem.data = jsonData;

    TIMMessage *msg = [[TIMMessage alloc] init];
    [msg addElem:customElem];
    
    TIMConversation *group_conversation = [[TIMManager sharedInstance] getConversation:TIM_GROUP receiver:_txtGroupId.text];
    [group_conversation sendMessage:msg succ:^{
        [self appendInfoText:@"消息发送成功"];
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"消息发送失败 code=%d err=%@", code, msg]];
    }];
}

// 获取我加入的群组
- (IBAction)getMyGroup:(id)sender {
    [[TIMGroupManager sharedInstance] getGroupList:^(NSArray *groupList) {
        if(groupList.count == 0) {
            [self appendInfoText:@"未加入任何群组"];
        }
        int i = 0;
        // 列表为 TIMGroupInfo，结构体只包含 group|groupName|groupType|faceUrl|allShutup|selfInfo 信息
        for (TIMGroupInfo *groupInfo in groupList) {
            i++;
            [self appendInfoText:[NSString stringWithFormat:@"加入的第%d个群组：", i]];
            [self appendInfoText:[NSString stringWithFormat:@"群组ID：%@", groupInfo.group]];
            [self appendInfoText:[NSString stringWithFormat:@"群名称：%@", groupInfo.groupName]];
            [self appendInfoText:[NSString stringWithFormat:@"群类型：%@", groupInfo.groupType]];
            [self appendInfoText:[NSString stringWithFormat:@"群头像：%@", groupInfo.faceURL]];
            [self appendInfoText:[NSString stringWithFormat:@"是否全体禁言：%d", groupInfo.allShutup]];
            [self appendInfoText:[NSString stringWithFormat:@"群组中的本人信息：%@", groupInfo.selfInfo]];
        }
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"获取我加入的群组失败 code=%d err=%@", code, msg]];
    }];
}

// 获取成员列表
- (IBAction)getGroupUserList:(id)sender {
    [[TIMGroupManager sharedInstance] getGroupMembers:_txtGroupId.text succ:^(NSArray *members) {
        NSLog(@"A");
        int i = 0;
        for (TIMGroupMemberInfo *memberInfo in members) {
            i++;
            [self appendInfoText:[NSString stringWithFormat:@"第%d个用户：", i]];
            [self appendInfoText:[NSString stringWithFormat:@"被操作成员：%@", memberInfo.member]];
            [self appendInfoText:[NSString stringWithFormat:@"群名片：%@", memberInfo.nameCard]];
            [self appendInfoText:[NSString stringWithFormat:@"加入群组时间：%ld", memberInfo.joinTime]];
            // 0 -- TIM_GROUP_MEMBER_UNDEFINED -- 未定义(没有获取该字段)
            // 200 -- TIM_GROUP_MEMBER_ROLE_MEMBER -- 群成员
            // 300 -- TIM_GROUP_MEMBER_ROLE_ADMIN -- 群管理员
            // 400 -- TIM_GROUP_MEMBER_ROLE_SUPER -- 群主
            [self appendInfoText:[NSString stringWithFormat:@"成员类型：%ld", memberInfo.role]];
            [self appendInfoText:[NSString stringWithFormat:@"禁言时间（剩余秒数）：%u", memberInfo.silentUntil]];
            // 自定义字段集合,key 是 NSString*类型,value 是 NSData*类型
            [self appendInfoText:[NSString stringWithFormat:@"自定义字段集合：%@", memberInfo.customInfo]];
        }
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"获取成员列表失败 code=%d err=%@", code, msg]];
    }];
}

// 获取我的用户信息
- (IBAction)getMyUserInfo:(id)sender {
    [[TIMFriendshipManager sharedInstance] getSelfProfile:^(TIMUserProfile *profile) {
        NSLog(@"用户ID：%@", profile.identifier);
        [self appendInfoText:[NSString stringWithFormat:@"用户ID：%@", profile.identifier]];
        [self appendInfoText:[NSString stringWithFormat:@"昵称：%@", profile.nickname]];
        [self appendInfoText:[NSString stringWithFormat:@"好友验证方式：%ld", (long)profile.allowType]];
        [self appendInfoText:[NSString stringWithFormat:@"头像：%@", profile.faceURL]];
        [self appendInfoText:[NSString stringWithFormat:@"签名：%@", profile.selfSignature]];
        [self appendInfoText:[NSString stringWithFormat:@"性别：%ld", (long)profile.gender]];
        [self appendInfoText:[NSString stringWithFormat:@"生日：%ld", (long)profile.birthday]];
        [self appendInfoText:[NSString stringWithFormat:@"区域：%@", profile.location]];
        [self appendInfoText:[NSString stringWithFormat:@"语言：%u", profile.language]];
        [self appendInfoText:[NSString stringWithFormat:@"等级：%u", profile.level]];
        [self appendInfoText:[NSString stringWithFormat:@"角色：%u", profile.role]];
        [self appendInfoText:[NSString stringWithFormat:@"自定义字段：%@", profile.customInfo]];
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"获取我的用户信息失败 code=%d err=%@", code, msg]];
    }];
}


// 发送群聊消息
- (IBAction)sendGroupMsg:(id)sender {
    TIMTextElem *textElem = [[TIMTextElem alloc] init];
    [textElem setText:_txtGroupMsg.text];
    
    TIMMessage *msg = [[TIMMessage alloc] init];
    [msg addElem:textElem];
    
    TIMConversation *group_conversation = [[TIMManager sharedInstance] getConversation:TIM_GROUP receiver:_txtGroupId.text];
    [group_conversation sendMessage:msg succ:^{
        [self appendInfoText:@"消息发送成功"];
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"消息发送失败 code=%d err=%@", code, msg]];
    }];
}

// 加入聊天室
- (IBAction)joinGroup:(id)sender {
    TIMManager * manager = [TIMManager sharedInstance];
    
    [[TIMGroupManager sharedInstance] joinGroup:_txtGroupId.text msg:manager.getLoginUser succ:^(){
        [self appendInfoText:@"申请加群/加入群聊 成功"];
    }fail:^(int code, NSString * err) {
        [self appendInfoText:[NSString stringWithFormat:@"申请加群/加入群聊 失败：：%d->%@", code, err]];
    }];
}

// 离开聊天室
- (IBAction)quitGroup:(id)sender {
    [[TIMGroupManager sharedInstance] quitGroup:_txtGroupId.text succ:^{
        [self appendInfoText:@"离开群聊成功"];
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"离开群聊失败：：%d->%@", code, msg]];
    }];
}

// 删除群组成员
- (IBAction)deleteGroupUser:(id)sender {
    NSMutableArray * members = [[NSMutableArray alloc] init];
    [members addObject:@"jerry"];
    
    [[TIMGroupManager sharedInstance] deleteGroupMemberWithReason:_txtGroupId.text reason:@"发广告" members:members succ:^(NSArray *members) {
        for (TIMGroupMemberResult * result in members) {
            [self appendInfoText:[NSString stringWithFormat:@"user %@ status %ld", result.member, (long)result.status]];
        }
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"删除群组成员失败：：%d->%@", code, msg]];
    }];
}

// 创建聊天室
- (IBAction)createGroup:(id)sender {
    //每次创建的聊天室groupId不一样，证明groupName只是一个标识，创建了多个叫这个名字的聊天室。
    int result = [[TIMGroupManager sharedInstance] createChatRoomGroup:nil groupName:@"wayne's first chatroom" succ:^(NSString *groupId) {
        [self appendInfoText:[NSString stringWithFormat:@"创建聊天室成功，groupId：%@", groupId]];
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"创建聊天室失败：：%d->%@", code, msg]];
    }];
    [self appendInfoText:[NSString stringWithFormat:@"创建结果：%d", result]];
}

// 自定义群组 ID 创建群组
- (IBAction)createGroupById:(id)sender {
    int result = [[TIMGroupManager sharedInstance] createGroup:@"Public" groupId:@"group23" groupName:@"我的聊天室" succ:^(NSString *groupId) {
        [self appendInfoText:[NSString stringWithFormat:@"创建聊天室成功，groupId：%@", groupId]];
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"创建聊天室失败：：%d->%@", code, msg]];
    }];
    [self appendInfoText:[NSString stringWithFormat:@"创建结果：%d", result]];
}

// 创建指定属性群组(AUTH)
- (IBAction)createDIYGroupAuth:(id)sender {
    TIMCreateGroupInfo *groupInfo = [[TIMCreateGroupInfo alloc] init];
    groupInfo.group = _txtGroupId.text; // 群组Id,nil则使用系统默认Id
    groupInfo.groupName = @"ofweek led在线研讨会"; // 群名
    groupInfo.groupType = @"Public"; // 群类型：Private,Public,ChatRoom,AVChatRoom
    groupInfo.setAddOpt = YES; // 是否设置入群选项，Private类型群组请设置为false
    groupInfo.addOpt = TIM_GROUP_ADD_AUTH; // 入群选项,TIM_GROUP_ADD_FORBID(禁止加群),TIM_GROUP_ADD_AUTH(需要管理员审批),TIM_GROUP_ADD_ANY(任何人可以加入)
    groupInfo.maxMemberNum = 0; // 最大成员数，填 0 则系统使用默认值
    groupInfo.notification = @"这是群公告"; // 群公告
    groupInfo.introduction = @"这是群简介"; // 群简介
    groupInfo.faceURL = @"https://www.ofweek.com/Upload/seminar/2020-4/202041014384346.jpg"; // 群头像
//    groupInfo.customInfo = [[NSDictionary alloc] initWithObjects:nil forKeys:nil]; // 自定义字段集合,key 是 NSString* 类型，value 是 NSData* 类型
//    groupInfo.membersInfo = [NSArray arrayWithObject:nil]; // 创建成员（TIMCreateGroupMemberInfo*）列表
    

    [[TIMGroupManager sharedInstance] createGroup:groupInfo succ:^(NSString *groupId) {
        [self appendInfoText:[NSString stringWithFormat:@"创建聊天室成功，groupId：%@", groupId]];
    } fail:^(int code, NSString *msg) {
        [self appendInfoText:[NSString stringWithFormat:@"创建聊天室失败：：%d->%@", code, msg]];
    }];
}

// 创建指定属性群组(ANY)
- (IBAction)createDIYGroup:(id)sender {
    TIMCreateGroupInfo *groupInfo = [[TIMCreateGroupInfo alloc] init];
    groupInfo.group = _txtGroupId.text; // 群组Id,nil则使用系统默认Id
    groupInfo.groupName = @"ofweek led在线研讨会"; // 群名
    groupInfo.groupType = @"Public"; // 群类型：Private,Public,ChatRoom,AVChatRoom
    groupInfo.setAddOpt = YES; // 是否设置入群选项，Private类型群组请设置为false
    groupInfo.addOpt = TIM_GROUP_ADD_ANY; // 入群选项,TIM_GROUP_ADD_FORBID(禁止加群),TIM_GROUP_ADD_AUTH(需要管理员审批),TIM_GROUP_ADD_ANY(任何人可以加入)
    groupInfo.maxMemberNum = 0; // 最大成员数，填 0 则系统使用默认值
    groupInfo.notification = @"这是群公告"; // 群公告
    groupInfo.introduction = @"这是群简介"; // 群简介
    groupInfo.faceURL = @"https://www.ofweek.com/Upload/seminar/2020-4/202041014384346.jpg"; // 群头像
//    groupInfo.customInfo = [[NSDictionary alloc] initWithObjects:nil forKeys:nil]; // 自定义字段集合,key 是 NSString* 类型，value 是 NSData* 类型
//    groupInfo.membersInfo = [NSArray arrayWithObject:nil]; // 创建成员（TIMCreateGroupMemberInfo*）列表
    

    [[TIMGroupManager sharedInstance] createGroup:groupInfo succ:^(NSString *groupId) {
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

     TIMManager * manager = [TIMManager sharedInstance];

    
    
    if([manager setUserConfig:userConfig] == 0) {
        [self appendInfoText:@"设置用户参数成功"];
    }
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
//    [self appendInfoText:@"收到了群tips回调，参数为群tips消息(TIMGroupTipsElem*)elem"];
    [self appendInfoText:[NSString stringWithFormat:@"收到了群事件通知回调(tip)，类型是:%ld", (long)elem.type]];
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

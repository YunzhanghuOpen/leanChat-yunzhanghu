//
//  RedpacketTakenMessageTipCell.h
//  RCloudMessage
//
//  Created by YANG HONGBO on 2016-4-27.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif

#define REDPACKET_TAKEN_MESSAGE_TOP_BOTTOM_PADDING 20
#define REDPACKET_MESSAGE_TOP_BOTTOM_PADDING 40

@interface RedpacketTakenMessageCell : LCCKChatMessageCell<LCCKChatMessageCellSubclassing>

@end

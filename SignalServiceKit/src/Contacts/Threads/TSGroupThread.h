//
//  Copyright (c) 2020 Open Whisper Systems. All rights reserved.
//

#import "TSGroupModel.h"
#import "TSThread.h"

NS_ASSUME_NONNULL_BEGIN

@class MessageBodyRanges;
@class SDSAnyReadTransaction;
@class SDSAnyWriteTransaction;
@class TSAttachmentStream;
@class TSGroupModelV2;

extern NSString *const TSGroupThreadAvatarChangedNotification;
extern NSString *const TSGroupThread_NotificationKey_UniqueId;

@interface TSGroupThread : TSThread

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
         conversationColorName:(ConversationColorName)conversationColorName
                  creationDate:(nullable NSDate *)creationDate
                    isArchived:(BOOL)isArchived
          lastInteractionRowId:(int64_t)lastInteractionRowId
                  messageDraft:(nullable NSString *)messageDraft
                mutedUntilDate:(nullable NSDate *)mutedUntilDate
         shouldThreadBeVisible:(BOOL)shouldThreadBeVisible NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithUniqueId:(NSString *)uniqueId NS_UNAVAILABLE;

- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

// This method should only be called by GroupManager.
- (instancetype)initWithGroupModelPrivate:(TSGroupModel *)groupModel
                              transaction:(SDSAnyReadTransaction *)transaction NS_DESIGNATED_INITIALIZER;

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
           conversationColorName:(ConversationColorName)conversationColorName
                    creationDate:(nullable NSDate *)creationDate
                      isArchived:(BOOL)isArchived
                  isMarkedUnread:(BOOL)isMarkedUnread
            lastInteractionRowId:(int64_t)lastInteractionRowId
       lastVisibleSortIdObsolete:(uint64_t)lastVisibleSortIdObsolete
lastVisibleSortIdOnScreenPercentageObsolete:(double)lastVisibleSortIdOnScreenPercentageObsolete
         mentionNotificationMode:(TSThreadMentionNotificationMode)mentionNotificationMode
                    messageDraft:(nullable NSString *)messageDraft
          messageDraftBodyRanges:(nullable MessageBodyRanges *)messageDraftBodyRanges
                  mutedUntilDate:(nullable NSDate *)mutedUntilDate
           shouldThreadBeVisible:(BOOL)shouldThreadBeVisible
                      groupModel:(TSGroupModel *)groupModel
NS_DESIGNATED_INITIALIZER NS_SWIFT_NAME(init(grdbId:uniqueId:conversationColorName:creationDate:isArchived:isMarkedUnread:lastInteractionRowId:lastVisibleSortIdObsolete:lastVisibleSortIdOnScreenPercentageObsolete:mentionNotificationMode:messageDraft:messageDraftBodyRanges:mutedUntilDate:shouldThreadBeVisible:groupModel:));

// clang-format on

// --- CODE GENERATION MARKER

@property (nonatomic, readonly) TSGroupModel *groupModel;

+ (nullable instancetype)fetchWithGroupId:(NSData *)groupId
                              transaction:(SDSAnyReadTransaction *)transaction
    NS_SWIFT_NAME(fetch(groupId:transaction:));

@property (nonatomic, readonly) NSString *groupNameOrDefault;
@property (nonatomic, readonly, class) NSString *defaultGroupName;

// all group threads containing recipient as a member
+ (NSArray<TSGroupThread *> *)groupThreadsWithAddress:(SignalServiceAddress *)address
                                          transaction:(SDSAnyReadTransaction *)transaction;

#pragma mark - Update With...

// This method should only be called by GroupManager.
- (void)updateWithGroupModel:(TSGroupModel *)groupModel transaction:(SDSAnyWriteTransaction *)transaction;

#pragma mark -

+ (ConversationColorName)defaultConversationColorNameForGroupId:(NSData *)groupId;

@end

NS_ASSUME_NONNULL_END

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getUserLocale } from './utils/localeHelper';

interface UpdateData {
  groupId: string;
  authorCpId: string;
  type: string;
  content: string;
  isAnonymous: boolean;
  createdAt: any;
}

/**
 * Send notifications when a new update is posted to a group
 */
export const sendUpdateNotification = functions.firestore
  .document('group_updates/{updateId}')
  .onCreate(async (snapshot, context) => {
    try {
      const updateId = context.params.updateId;
      const updateData = snapshot.data() as UpdateData;
      
      console.log(`📢 [UPDATE_NOTIFICATION] New update posted: ${updateId}`);

      const { groupId, authorCpId, type, content, isAnonymous } = updateData;

      // Get group data
      const groupDoc = await admin.firestore().collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        console.log('❌ Group not found');
        return;
      }
      
      const groupData = groupDoc.data()!;
      const groupName = groupData.name || 'Group';

      // Get all group members except author
      const membershipsSnapshot = await admin.firestore()
        .collection('group_memberships')
        .where('groupId', '==', groupId)
        .where('isActive', '==', true)
        .get();

      console.log(`👥 Found ${membershipsSnapshot.size} members`);

      // Filter out author and get user IDs
      const memberPromises = membershipsSnapshot.docs
        .filter(doc => doc.data().cpId !== authorCpId)
        .map(async (memberDoc) => {
          const memberData = memberDoc.data();
          
          // Get user mapping
          const mappingDoc = await admin.firestore()
            .collection('userProfileMappings')
            .doc(memberData.cpId)
            .get();
          
          if (!mappingDoc.exists) return null;
          
          const userUID = mappingDoc.data()?.userUID;
          if (!userUID) return null;

          // Get user document for FCM token
          const userDoc = await admin.firestore()
            .collection('users')
            .doc(userUID)
            .get();
          
          if (!userDoc.exists) return null;
          
          const userData = userDoc.data()!;
          const fcmToken = userData.messagingToken || userData.fcmToken;
          const locale = getUserLocale(userData);
          
          if (!fcmToken) return null;

          return { fcmToken, locale, cpId: memberData.cpId };
        });

      const members = (await Promise.all(memberPromises)).filter(m => m !== null);

      console.log(`🎯 ${members.length} members with FCM tokens`);

      if (members.length === 0) {
        console.log('📭 No members to notify');
        return;
      }

      // Get author name if not anonymous
      let authorName = 'A member';
      if (!isAnonymous) {
        const authorDoc = await admin.firestore()
          .collection('communityProfiles')
          .doc(authorCpId)
          .get();
        
        if (authorDoc.exists) {
          authorName = authorDoc.data()?.displayName || 'A member';
        }
      } else {
        authorName = 'An anonymous member';
      }

      // Send notifications
      const messaging = admin.messaging();
      const notifications = members.map(async (member) => {
        try {
          const title = member.locale === 'arabic' 
            ? `تحديث جديد في ${groupName}`
            : `New update in ${groupName}`;
          
          const body = member.locale === 'arabic'
            ? `${authorName} شارك تحديثاً جديداً`
            : `${authorName} shared an update`;

          await messaging.send({
            token: member.fcmToken,
            notification: { title, body },
            data: {
              type: 'group_update',
              groupId,
              updateId,
              locale: member.locale,
            },
            android: {
              priority: 'high',
              notification: {
                channelId: 'high_importance_channel',
                priority: 'high',
              },
            },
            apns: {
              payload: {
                aps: {
                  alert: { title, body },
                  badge: 1,
                  sound: 'default',
                },
              },
            },
          });

          console.log(`✅ Notification sent to ${member.cpId}`);
        } catch (error) {
          console.error(`❌ Error sending to ${member.cpId}:`, error);
        }
      });

      await Promise.all(notifications);
      console.log(`✅ [UPDATE_NOTIFICATION] Complete: ${notifications.length} sent`);

    } catch (error) {
      console.error('❌ [UPDATE_NOTIFICATION] Error:', error);
    }
  });

/**
 * Send notification when someone comments on an update
 */
export const sendCommentNotification = functions.firestore
  .document('update_comments/{commentId}')
  .onCreate(async (snapshot, context) => {
    try {
      const commentData = snapshot.data();
      const { updateId, groupId, authorCpId, content } = commentData;

      console.log(`💬 [COMMENT_NOTIFICATION] New comment on update: ${updateId}`);

      // Get update data
      const updateDoc = await admin.firestore()
        .collection('group_updates')
        .doc(updateId)
        .get();
      
      if (!updateDoc.exists) {
        console.log('❌ Update not found');
        return;
      }

      const updateData = updateDoc.data()!;
      const updateAuthorCpId = updateData.authorCpId;

      // Don't notify if commenting on own update
      if (updateAuthorCpId === authorCpId) {
        console.log('⏭️ User commented on their own update');
        return;
      }

      // Get update author's user ID and FCM token
      const mappingDoc = await admin.firestore()
        .collection('userProfileMappings')
        .doc(updateAuthorCpId)
        .get();
      
      if (!mappingDoc.exists) return;

      const userUID = mappingDoc.data()?.userUID;
      if (!userUID) return;

      const userDoc = await admin.firestore()
        .collection('users')
        .doc(userUID)
        .get();
      
      if (!userDoc.exists) return;

      const userData = userDoc.data()!;
      const fcmToken = userData.messagingToken || userData.fcmToken;
      const locale = getUserLocale(userData);

      if (!fcmToken) {
        console.log('📭 No FCM token');
        return;
      }

      // Get commenter name
      const commenterDoc = await admin.firestore()
        .collection('communityProfiles')
        .doc(authorCpId)
        .get();
      
      const commenterName = commenterDoc.exists
        ? commenterDoc.data()?.displayName || 'Someone'
        : 'Someone';

      // Send notification
      const title = locale === 'arabic'
        ? 'تعليق جديد'
        : 'New comment';
      
      const body = locale === 'arabic'
        ? `${commenterName} علق على تحديثك`
        : `${commenterName} commented on your update`;

      await admin.messaging().send({
        token: fcmToken,
        notification: { title, body },
        data: {
          type: 'update_comment',
          groupId,
          updateId,
          locale,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'high_importance_channel',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: { title, body },
              badge: 1,
              sound: 'default',
            },
          },
        },
      });

      console.log(`✅ [COMMENT_NOTIFICATION] Sent to ${updateAuthorCpId}`);

    } catch (error) {
      console.error('❌ [COMMENT_NOTIFICATION] Error:', error);
    }
  });


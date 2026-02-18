'use client';

import React, { useState, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Skeleton } from '@/components/ui/skeleton';
import { useTranslation } from '@/contexts/TranslationContext';
import { toast } from 'sonner';
import {
  Send,
  User,
  Shield,
  MessageCircle,
  Clock,
  ChevronDown,
  ChevronUp,
  Zap,
} from 'lucide-react';

// Firebase imports
import { useCollection, useDocument } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, addDoc, updateDoc, doc, Timestamp, increment } from 'firebase/firestore';
import { db } from '@/lib/firebase';

// Import notification payload utilities
import { createNewMessagePayload } from '@/utils/notificationPayloads';

interface ReportMessage {
  id: string;
  reportId: string;
  senderId: string;
  senderRole: 'user' | 'admin';
  message: string;
  timestamp: Timestamp;
  isRead: boolean;
}

interface ConversationViewProps {
  reportId: string;
  reportStatus: string;
  onStatusChange?: () => void;
}

interface UserProfile {
  uid: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  locale?: string;
  createdAt: Timestamp;
  lastLoginAt?: Timestamp;
  messagingToken?: string;
}

export default function ConversationView({ reportId, reportStatus, onStatusChange }: ConversationViewProps) {
  const { t, locale } = useTranslation();
  const [newMessage, setNewMessage] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [showQuickReplies, setShowQuickReplies] = useState(false);

  // Quick reply templates
  const quickReplies = [
    {
      title: "🟡 مشكلة في البيانات – لا يوجد خلل",
      message: "تمت مراجعة بياناتك، ولم نجد أي خلل. تأكد من تحديث التطبيق، وإذا المشكلة مستمرة، أرسل لنا تفاصيل أو صورة وسنساعدك فورًا 💛"
    },
    {
      title: "🟡 المشكلة بسبب عدم إدخال المتابعات",
      message: "تمت المراجعة، ويبدو أنك لم تُدخل بعض المتابعات اليومية. أضف المتابعات من التقويم لتحديث الإحصائيات بدقة، والمداومة مهمة لدقة البيانات 💛"
    },
    {
      title: "🟡 المشكلة تم حلها واستعادة البيانات",
      message: "تم حل المشكلة الآن، وتم استعادة البيانات لحسابك. تقدر تراجعها داخل التطبيق، وإذا لاحظت شيء ناقص بلغنا فورًا 💛"
    },
    {
      title: "🟡 المشكلة لا يوجد شيء مفقود",
      message: "تمت مراجعة بياناتك ولم نجد أي بيانات مفقودة. هل أنت متأكد أنك لم تقم بإعادة التعيين من قبل؟ إذا عندك تفاصيل إضافية بلغنا 💛"
    },
    {
      title: "🟡 الأيام غير صحيحة",
      message: "يرجى مراجعة تاريخ البداية من التقويم، قد يكون فيه يوم ناقص. إذا تقدر ترسل لنا التفاصيل، نساعدك بشكل أدق بإذن الله 💛"
    },
    {
      title: "🟡 الاتهام بفقد البيانات بعد التحديث",
      message: "نعتذر عن الإرباك، تم استرجاع بياناتك الآن بعد المراجعة. نحرص على الحفاظ على بيانات الجميع، ونقدّر صبرك وثقتك 💛"
    },
    {
      title: "🟡 طلب تصفير البيانات",
      message: "يمكنك تصفير الإحصائيات من داخل التطبيق عبر صفحة \"الحساب\" > \"إعادة ضبط الإحصائيات\". وإذا احتجت مساعدة، نحن معك 💛"
    },
    {
      title: "🟡 اقتراحات مميزة",
      message: "اقتراحك رائع ومفيد جدًا 🙏 نعمل على تطوير ميزات مثل [اذكر الميزة]، وإن شاء الله تشوفها قريبًا ضمن التحديثات القادمة 💛"
    }
  ];

  // Handle quick reply selection
  const handleQuickReplySelect = (message: string) => {
    setNewMessage(message);
    setShowQuickReplies(false);
  };

  // Fetch conversation messages
  const [messagesSnapshot, messagesLoading, messagesError] = useCollection(
    query(
      collection(db, 'usersReports', reportId, 'messages'),
      orderBy('timestamp', 'asc')
    )
  );

  // Fetch report data to get user ID
  const [reportSnapshot] = useDocument(
    doc(db, 'usersReports', reportId)
  );

  // Fetch user data for notifications
  const [userSnapshot] = useDocument(
    reportSnapshot?.exists() ? doc(db, 'users', reportSnapshot.data().uid) : null
  );

  // Parse user data
  const user: UserProfile | null = userSnapshot?.exists() ? {
    uid: userSnapshot.id,
    email: userSnapshot.data().email || '',
    displayName: userSnapshot.data().displayName,
    photoURL: userSnapshot.data().photoURL,
    locale: userSnapshot.data().locale || 'en',
    createdAt: userSnapshot.data().createdAt || Timestamp.now(),
    lastLoginAt: userSnapshot.data().lastLoginAt,
    messagingToken: userSnapshot.data().messagingToken,
  } : null;

  // Convert messages data
  const messages: ReportMessage[] = useMemo(() => {
    if (!messagesSnapshot) return [];
    
    return messagesSnapshot.docs.map(doc => ({
      id: doc.id,
      reportId: reportId,
      senderId: doc.data().senderId || '',
      senderRole: doc.data().senderRole || 'user',
      message: doc.data().message || '',
      timestamp: doc.data().timestamp || Timestamp.now(),
      isRead: doc.data().isRead ?? false,
    }));
  }, [messagesSnapshot, reportId]);

  const formatMessageTime = (timestamp: Timestamp) => {
    const now = new Date();
    const messageTime = timestamp.toDate();
    const diffMs = now.getTime() - messageTime.getTime();
    const diffMinutes = Math.floor(diffMs / (1000 * 60));
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffMinutes < 1) {
      return t('modules.userManagement.reports.reportDetails.justNow') || 'Just now';
    } else if (diffMinutes < 60) {
      return t('modules.userManagement.reports.reportDetails.minutesAgo')?.replace('{count}', diffMinutes.toString()) || `${diffMinutes} minutes ago`;
    } else if (diffHours < 24) {
      return t('modules.userManagement.reports.reportDetails.hoursAgo')?.replace('{count}', diffHours.toString()) || `${diffHours} hours ago`;
    } else {
      return t('modules.userManagement.reports.reportDetails.daysAgo')?.replace('{count}', diffDays.toString()) || `${diffDays} days ago`;
    }
  };

  const canSendMessage = reportStatus !== 'closed' && reportStatus !== 'finalized';

  const sendMessageNotificationToUser = async () => {
    if (!user?.messagingToken || !user?.locale) {
      console.warn('No messaging token or locale found for user');
      return;
    }

    try {
      const userLocale = user.locale === 'arabic' ? 'ar' : 'en';
      
      // Get localized notification content for new message
      const title = userLocale === 'ar' 
        ? 'رسالة جديدة من المدير'
        : 'New Message from Admin';
      const body = userLocale === 'ar' 
        ? 'لديك رسالة جديدة بخصوص تقريرك'
        : 'You have a new message regarding your report';

      // Use the new payload structure with navigation data
      const payload = createNewMessagePayload(
        title,
        body,
        reportId,
        'admin',
        userLocale
      );

      const response = await fetch('/api/admin/notifications/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          token: user.messagingToken,
          ...payload
        }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ error: 'Unknown error' }));
        const errorMessage = errorData?.error || `HTTP ${response.status}: ${response.statusText}`;
        console.error('Failed to send message notification:', errorMessage);
        // Don't throw - notification failure shouldn't block message sending
        return;
      }

      const result = await response.json();
      console.log('Message notification sent to user:', result.messageId);
    } catch (error) {
      // Log error but don't throw - notification failure shouldn't block message sending
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error('Error sending message notification:', errorMessage);
    }
  };

  const handleSendMessage = async () => {
    if (!newMessage.trim() || !canSendMessage) {
      toast.error(t('modules.userManagement.reports.reportDetails.messageRequired') || 'Message is required');
      return;
    }

    setIsSending(true);
    try {
      // Add message to subcollection
      await addDoc(collection(db, 'usersReports', reportId, 'messages'), {
        reportId: reportId,
        senderId: 'admin',
        senderRole: 'admin',
        message: newMessage.trim(),
        timestamp: Timestamp.now(),
        isRead: false,
      });

      // Update report metadata
      await updateDoc(doc(db, 'usersReports', reportId), {
        status: 'inProgress',
        lastUpdated: Timestamp.now(),
        messagesCount: increment(1),
      });

      // Send push notification to user about the new message
      await sendMessageNotificationToUser();

      setNewMessage('');
      toast.success(t('modules.userManagement.reports.reportDetails.messageSent') || 'Message sent successfully');
      
      // Trigger status change callback if provided
      onStatusChange?.();
    } catch (error) {
      console.error('Error sending message:', error);
      toast.error(t('modules.userManagement.reports.reportDetails.messageError') || 'Failed to send message');
    } finally {
      setIsSending(false);
    }
  };

  const remainingChars = 1000 - newMessage.length;

  if (messagesError) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <MessageCircle className="h-5 w-5" />
            {t('modules.userManagement.reports.reportDetails.conversation') || 'Conversation'}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8">
            <p className="text-red-500">Error loading conversation: {messagesError.message}</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <MessageCircle className="h-5 w-5" />
          {t('modules.userManagement.reports.reportDetails.conversation') || 'Conversation'}
          <Badge variant="outline" className="ml-auto">
            {messages.length} {messages.length === 1 ? 'message' : 'messages'}
          </Badge>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Message History */}
        <div className="space-y-4 max-h-96 overflow-y-auto">
          {messagesLoading ? (
            <div className="space-y-3">
              {[...Array(2)].map((_, i) => (
                <div key={i} className="flex gap-3">
                  <Skeleton className="h-8 w-8 rounded-full" />
                  <div className="space-y-2 flex-1">
                    <Skeleton className="h-4 w-24" />
                    <Skeleton className="h-16 w-full" />
                  </div>
                </div>
              ))}
            </div>
          ) : messages.length === 0 ? (
            <div className="text-center py-8">
              <MessageCircle className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <p className="text-muted-foreground">
                {t('modules.userManagement.reports.reportDetails.noMessages') || 'No messages in this conversation yet'}
              </p>
            </div>
          ) : (
            messages.map((message) => (
              <div key={message.id} className="flex gap-3">
                <Avatar className="h-8 w-8">
                  <AvatarFallback>
                    {message.senderRole === 'admin' ? (
                      <Shield className="h-4 w-4" />
                    ) : (
                      <User className="h-4 w-4" />
                    )}
                  </AvatarFallback>
                </Avatar>
                
                <div className="flex-1 space-y-1">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium">
                      {message.senderRole === 'admin' 
                        ? t('modules.userManagement.reports.reportDetails.adminMessage') || 'Admin'
                        : t('modules.userManagement.reports.reportDetails.userMessage') || 'User'
                      }
                    </span>
                    <div className="flex items-center gap-1 text-xs text-muted-foreground">
                      <Clock className="h-3 w-3" />
                      {formatMessageTime(message.timestamp)}
                    </div>
                  </div>
                  
                  <div className={`p-3 rounded-lg max-w-lg ${
                    message.senderRole === 'admin'
                      ? 'bg-blue-50 border border-blue-200'
                      : 'bg-gray-50 border border-gray-200'
                  }`}>
                    <p className="text-sm whitespace-pre-wrap">{message.message}</p>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>

        {/* Quick Replies */}
        {canSendMessage && (
          <div className="border-t pt-4">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setShowQuickReplies(!showQuickReplies)}
              className="mb-3 flex items-center gap-2"
            >
              <Zap className="h-4 w-4" />
              الردود السريعة
              {showQuickReplies ? (
                <ChevronUp className="h-4 w-4" />
              ) : (
                <ChevronDown className="h-4 w-4" />
              )}
            </Button>
            
            {showQuickReplies && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-2 mb-4 max-h-60 overflow-y-auto">
                {quickReplies.map((reply, index) => (
                  <Button
                    key={index}
                    variant="ghost"
                    size="sm"
                    onClick={() => handleQuickReplySelect(reply.message)}
                    className="text-right justify-start h-auto p-3 text-wrap border border-gray-200 hover:bg-yellow-50 hover:border-yellow-300"
                  >
                    <div className="text-xs text-right leading-relaxed">
                      {reply.title}
                    </div>
                  </Button>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Message Input */}
        {canSendMessage ? (
          <div className="space-y-3">
            <div>
              <Textarea
                value={newMessage}
                onChange={(e) => setNewMessage(e.target.value)}
                placeholder={t('modules.userManagement.reports.reportDetails.messagePlaceholder') || 'Type your message to the user...'}
                rows={3}
                maxLength={1000}
                disabled={isSending}
              />
              <div className="flex justify-between items-center mt-2">
                <span className="text-sm text-muted-foreground">
                  {t('modules.userManagement.reports.reportDetails.maxCharacters') || 'Maximum 1000 characters'}
                </span>
                <span className={`text-sm ${remainingChars < 20 ? 'text-orange-600' : 'text-muted-foreground'}`}>
                  {remainingChars} {t('modules.userManagement.reports.reportDetails.charactersRemaining') || 'characters remaining'}
                </span>
              </div>
            </div>

            <div className="flex justify-between items-center">
              <p className="text-sm text-muted-foreground">
                {t('modules.userManagement.reports.reportDetails.messageHelp') || 'Your message will be sent to the user immediately'}
              </p>
              <Button
                onClick={handleSendMessage}
                disabled={!newMessage.trim() || isSending || remainingChars < 0}
              >
                <Send className="h-4 w-4 mr-2" />
                {isSending 
                  ? t('modules.userManagement.reports.reportDetails.updating') || 'Sending...'
                  : t('modules.userManagement.reports.reportDetails.sendMessage') || 'Send Message'
                }
              </Button>
            </div>
          </div>
        ) : (
          <div className="border-t pt-4">
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3">
              <p className="text-sm text-yellow-800">
                {t('modules.userManagement.reports.statusTransitions.cannotSendMessageToClosedReport') || 'Cannot send messages to closed or finalized reports'}
              </p>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
} 
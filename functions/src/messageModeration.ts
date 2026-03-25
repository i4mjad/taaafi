import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { openaiApiKey, moderateDocument } from './moderation/pipeline';

export const moderateMessage = onDocumentCreated(
  {
    document: 'group_messages/{messageId}',
    secrets: [openaiApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 30,
    maxInstances: 50,
  },
  async (event) => {
    await moderateDocument(event, {
      textExtractor: (data) => data.body || '',
      authorIdField: 'senderCpId',
      contentType: 'group_message',
      autoHideOnFlag: true,
    });
  },
);

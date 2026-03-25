import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { openaiApiKey, moderateDocument } from './moderation/pipeline';

export const moderateComment = onDocumentCreated(
  {
    document: 'comments/{commentId}',
    secrets: [openaiApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 30,
    maxInstances: 50,
  },
  async (event) => {
    await moderateDocument(event, {
      textExtractor: (data) => data.body || '',
      authorIdField: 'authorCPId',
      contentType: 'comment',
      autoHideOnFlag: true,
    });
  },
);

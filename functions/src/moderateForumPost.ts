import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { openaiApiKey, moderateDocument } from './moderation/pipeline';

export const moderateForumPost = onDocumentCreated(
  {
    document: 'forumPosts/{postId}',
    secrets: [openaiApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 30,
    maxInstances: 50,
  },
  async (event) => {
    await moderateDocument(event, {
      textExtractor: (data) => `${data.title || ''}\n${data.body || ''}`.trim(),
      authorIdField: 'authorCPId',
      contentType: 'forum_post',
      autoHideOnFlag: true,
    });
  },
);

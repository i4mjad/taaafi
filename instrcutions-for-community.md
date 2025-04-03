Thank you for the detailed requirements and existing documentation. Before moving forward with finalizing the schema and generating the code scaffolding instructions for the Ta'aafi Community feature, I need a few clarifications:

1. **Community Profile Storage:**
   - You mentioned that the community profile should be separate from the user document. Would you like to store these in a dedicated collection (e.g., `communityProfiles`) that references the user’s UID, or as a subcollection under each user document?

- Yes, it should be in a dedicated collection

2. **Moderation & Automated Content Scanning:**

   - For content moderation, do you plan to use Firebase ML Kit or another third-party service for automated scanning of text and media?
   - Yes let's use Firebase ML Kit. However, I have a concern about using it with Arabic, since the content is mostly in arabic

   - Do you have any specific guidelines (e.g., thresholds or filtering criteria) for what content should be flagged automatically?
   - Yes, I will provide a list of words that is not allowed to be posted.

3. **Naming Conventions & Firestore Indexes:**

   - Are there any specific naming conventions you’d like for collections/documents (e.g., `posts`, `comments`, `users`, etc.)?
   - Those are fine
   - Do you have any anticipated queries that we should account for when suggesting Firestore indexes?
   - Not at the moment, however you should suggest indexes that will make sure the data access is as smooth and efficent as much

4. **Existing Codebase & Style Guidelines:**

   - Do you have any existing repositories or additional style guidelines (beyond the provided Riverpod/Flutter guidelines) that we should reference to maintain consistency with your current code infrastructure?
   - No

5. **Notification Triggering:**
   - For the notifications handled via FCM, could you confirm if you’d like Cloud Functions to trigger notifications on specific events (e.g., new post by a followed user, comment on a post, etc.)?
   - Yes I want to use that also consider using topics subscription in FCM
   - Are there any additional customizations needed for notification scheduling (like the daily random check-ins)?
   - Not at the moment

Once I have these clarifications, I can finalize the Firebase schema and provide you with detailed instructions (and prompts for Cursor Agents) to scaffold the feature for both your Flutter mobile app and Angular admin panel. Let me know if there are any other details or preferences you’d like to add!

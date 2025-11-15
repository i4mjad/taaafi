# Database Cleanup Scripts

## Remove One-Time Tasks Script

This script removes all one-time tasks from group challenges in Firestore after removing one-time task support from the app.

### Prerequisites

1. Make sure you have Firebase configured in your project
2. Ensure you have proper Firebase Admin permissions

### How to Run

1. **Using Firebase CLI and Cloud Functions:**

   If you have Firebase CLI set up, you can run this as a one-off script:
   
   ```bash
   # From the project root
   cd scripts
   dart run remove_onetime_tasks.dart
   ```

2. **Using Firebase Console (Manual Method):**

   If the script doesn't work, you can manually remove one-time tasks:
   
   a. Go to Firebase Console
   b. Navigate to Firestore Database
   c. Open the `group_challenges` collection
   d. For each challenge document:
      - Edit the `tasks` array
      - Remove any task with `"frequency": "one_time"`
      - Save the document

### What the Script Does

1. Connects to Firestore
2. Queries all documents in the `group_challenges` collection
3. For each challenge:
   - Reads the `tasks` array
   - Filters out any task with `frequency: 'one_time'`
   - Updates the challenge document with the filtered tasks
4. Prints a summary of changes made

### Safety

- The script only removes tasks with `frequency: 'one_time'`
- It preserves all daily and weekly tasks
- It will show you which challenges were updated

### After Running

After running this script:
1. Verify in Firebase Console that one-time tasks are gone
2. Test the app to ensure everything works correctly
3. You can delete this script file if you no longer need it


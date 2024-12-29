## Instruction File for Activities Feature in Flutter with Firebase

### Overview

This document guides AI tools to implement the Activities feature in a Flutter app with Firebase. It supports managing, viewing, and interacting with activities.

### Prerequisites

1. **Architecture**: the activities is under vault feature folder as the following:

```
lib/
  features/
    vault/
      data/
        activities/
      application/
        activities/
      presentation/
        activities/
```

- data folder: this will contain anything related to the data like the models and repositories.
- application folder: this will contain anything related to business logic like the services. This could also hold the riverpod notifiers.
- presentation folder: this will contain all UI-related stuff.

### Feature Description

Overview about the feature: The aim of this feature is to allow the users to subscribe to a certain activity that is already defined.
The definition of the activity includes:

    1. Activity name.
    2. Activity description.
    3. Activity difficulty.
    4. Activity Tasks: Each activity could have more than one task, each activity task has the following:
         1. Task name.
         2. Task frequency.
         3. Task description.

I'm using Firestore as my database, I will mention later the structure of the documents.
Feel free to suggest any required edits that will make the database design better.

With the details above, you are required to implement the following functionalities based on the existing screens:

1. activities screen (lib/features/vault/presentation/activities/activities_screen.dart):

   1. The user can view the activities they are subscribed to with the following details:
      a. the activity name
      b. the activity starting date
      c. the progress (in percentage)
   2. The user can see today's due tasks and have the ability to mark them as completed with a checkbox.
   3. The user can navigate to see the details of a specific activity.
   4. The user can navigate to see all tasks.
   5. The user can navigate to a screen that shows the available activities for subscription.

2. all tasks screen (lib/features/vault/presentation/activities/all_tasks_screen.dart):

   1. The user can see all the tasks from all activities that they've subscribed to.
   2. Each task should have the task name and the activity name.

3. ongoing activity screen (lib/features/vault/presentation/activities/ongoing_activitiy_screen.dart):

   1. The user can see the details of the activity they've subscribed to.
   2. The following details need to be shown:
      1. Activity description
      2. Activity details related to the user:
         a. Subscription date
         b. Progress (in percentage)
         c. Activity difficulty (this comes from the activity definition, not specific to the user)
         d. Subscription period
      3. Activity tasks: Each task should have a button to show a modal that contains its details.
      4. Performance: Show how the user performed in the last 7 occurrences of this activity's tasks. Since activities' tasks have different frequencies, display the last 7 occurrences based on the activity.
   3. The user can see the settings for the activity, where they can restart the activity or remove the subscription.

4. add activity screen (lib/features/vault/presentation/activities/add_activity_screen.dart):

   1. The user can see the available activities to subscribe to.
   2. The user can see the following activity details:
      1. Activity name
      2. Activity difficulty
   3. The user should not be able to navigate to an activity they are currently subscribed to; a snackbar should be shown if they try.

5. activity overview screen (lib/features/vault/presentation/activities/activity_overview_screen.dart):

   1. The user can see the details of the activity they want to subscribe to.
   2. The following details need to be shown:
      1. Activity description.
      2. Activity details:
         a. Activity difficulty
         b. Subscription count
         c. Subscription date
         d. Subscription period
   3. Activity tasks: Each task should have a button to show a modal that contains its details.
   4. A button to show a subscribe modal. This will allow the user to select the subscription start and end date.

### Collections Document Structure:

- activities collection:
  - The collection is in the root of the collections and it is not nested.
  - This collection holds documents with the following structure:
    - activityDescription (string)
    - activityDifficulty (string)
    - activityName (string)
    - activityTasks (subcollection): Contains documents with the following structure:
      - taskDescription
      - taskFrequency
      - taskName

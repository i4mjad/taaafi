export interface Activity {
  activityId: string;
  activityName: string;
  activityDifficulty: string;
  activityDescription: string;
  activitySubscribersCount: number;
  activityTasks: ActivityTask[];
}
export interface ActivityDataModel {
  activityId: string;
  activityName: string;
  activityDifficulty: string;
  activityDescribition: string;
  activitySubscriptionSessions: ActivitySubscriptionSession[];
  activityTasks: ActivityTask[];
}

export interface ActivityTask {
  taskId: string;
  taskName: string;
  taskDescription: string;
  taskFrequency: TaskFrequency;
}
export interface ActivitySubscriptionSession {
  activitySubscriptionSessionId: string;
  userUid: string;
  subscribeDate: Date;
  isActive: boolean;
}

export enum TaskFrequency {
  Daily = 'daily',
  Weekly = 'weekly',
  Monthly = 'monthly',
}
export const fakeActivities: Activity[] = [
  {
    activityId: '1',
    activityName: 'Yoga',
    activityDifficulty: 'Medium',
    activityDescription: 'A series of stretching and breathing exercises.',
    activitySubscribersCount: 120,
    activityTasks: [
      {
        taskId: '1-1',
        taskName: 'Morning Yoga',
        taskDescription: 'Start your day with a morning yoga session.',
        taskFrequency: TaskFrequency.Daily,
      },
      {
        taskId: '1-2',
        taskName: 'Evening Yoga',
        taskDescription: 'End your day with a relaxing evening yoga session.',
        taskFrequency: TaskFrequency.Daily,
      },
    ],
  },
  {
    activityId: '2',
    activityName: 'Running',
    activityDifficulty: 'Hard',
    activityDescription: 'A high-intensity running activity.',
    activitySubscribersCount: 80,
    activityTasks: [
      {
        taskId: '2-1',
        taskName: 'Morning Run',
        taskDescription: 'Start your day with a morning run.',
        taskFrequency: TaskFrequency.Daily,
      },
      {
        taskId: '2-2',
        taskName: 'Weekend Long Run',
        taskDescription: 'A long run on the weekend.',
        taskFrequency: TaskFrequency.Weekly,
      },
    ],
  },
];

export const fakeActivityDataModels: ActivityDataModel[] = [
  {
    activityId: '1',
    activityName: 'Yoga',
    activityDifficulty: 'Medium',
    activityDescribition: 'A series of stretching and breathing exercises.',
    activitySubscriptionSessions: [
      {
        activitySubscriptionSessionId: '1-1',
        userUid: 'user-1',
        subscribeDate: new Date(),
        isActive: true,
      },
    ],
    activityTasks: [
      {
        taskId: '1-1',
        taskName: 'Morning Yoga',
        taskDescription: 'Start your day with a morning yoga session.',
        taskFrequency: TaskFrequency.Daily,
      },
      {
        taskId: '1-2',
        taskName: 'Evening Yoga',
        taskDescription: 'End your day with a relaxing evening yoga session.',
        taskFrequency: TaskFrequency.Daily,
      },
    ],
  },
  {
    activityId: '2',
    activityName: 'Running',
    activityDifficulty: 'Hard',
    activityDescribition: 'A high-intensity running activity.',
    activitySubscriptionSessions: [
      {
        activitySubscriptionSessionId: '2-1',
        userUid: 'user-2',
        subscribeDate: new Date(),
        isActive: true,
      },
    ],
    activityTasks: [
      {
        taskId: '2-1',
        taskName: 'Morning Run',
        taskDescription: 'Start your day with a morning run.',
        taskFrequency: TaskFrequency.Daily,
      },
      {
        taskId: '2-2',
        taskName: 'Weekend Long Run',
        taskDescription: 'A long run on the weekend.',
        taskFrequency: TaskFrequency.Weekly,
      },
    ],
  },
];

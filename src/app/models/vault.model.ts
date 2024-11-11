export interface Activity {
  activityId: string;
  activityName: string;
  activityDifficulty: string;
  activityDescription: string;
  activitySubscribersCount: number;
  activityTasks: ActivityTask[];
  createdAt?: Date;
}
export interface ActivityDataModel {
  activityName: string;
  activityDifficulty: string;
  activityDescription: string;
  activitySubscriptionSessions?: ActivitySubscriptionSession[];

  activityTasks?: ActivityTask[];
  createdAt?: Date;
}

export interface ActivityTask {
  taskId: string;
  taskName: string;
  taskDescription: string;
  taskFrequency: TaskFrequency;
  isDeleted: boolean;
}
export interface ActivitySubscriptionSession {
  activitySubscriptionSessionId: string;
  userUid: string;
  subscribeDate: Date;
  isActive: boolean;
}

export enum TaskFrequency {
  daily = 'daily',
  weekly = 'weekly',
  monthly = 'monthly',
}

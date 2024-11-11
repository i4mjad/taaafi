import {
  Activity,
  ActivityDataModel,
  ActivitySubscriptionSession,
  ActivityTask,
} from '../../models/vault.model';

export class CreateActivityAction {
  static readonly type = '[Vault] Create Activity Action';
  constructor(public activity: ActivityDataModel) {}
}

export class FetchActivitiesAction {
  static readonly type = '[Vault] Fetch Activities Action';
}

export class FetchActivityByIdAction {
  static readonly type = '[Vault] Fetch Activity By Id Action';
  constructor(public activityId: string) {}
}

export class FetchActivitySubscriptionSessionsAction {
  static readonly type = '[Vault] Fetch Activity Subscription Sessions Action';
  constructor(public activityId: string) {}
}

export class UpdateActivityAction {
  static readonly type = '[Vault] Update Activity Action';
  constructor(public activity: Activity) {}
}

export class UpdateActivityTasksAction {
  static readonly type = '[Vault] Update Activity Tasks Action';
  constructor(public activityId: string, public tasks: ActivityTask[]) {}
}

export class FetchActivityTasksAction {
  static readonly type = '[Vault] Fetch Activity Tasks Action';
  constructor(public activityId: string) {}
}

export class FetchActivityTaskByIdAction {
  static readonly type = '[Vault] Fetch Activity Task By Id Action';
  constructor(public activityId: string, public taskId: string) {}
}

export class DeleteActivityTaskAction {
  static readonly type = '[Vault] Delete Activity Task Action';
  constructor(public activityId: string, public taskId: string) {}
}

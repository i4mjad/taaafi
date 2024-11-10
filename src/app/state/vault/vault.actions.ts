import {
  ActivityDataModel,
  ActivitySubscriptionSession,
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

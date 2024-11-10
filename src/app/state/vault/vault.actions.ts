import { ActivityDataModel } from '../../models/vault.model';

export class CreateActivityAction {
  static readonly type = '[Vault] Create Activity Action';

  constructor(public activity: ActivityDataModel) {}
}

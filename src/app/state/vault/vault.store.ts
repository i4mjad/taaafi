import { Injectable } from '@angular/core';
import { State, Selector, Action, StateContext } from '@ngxs/store';
import { catchError, throwError, from } from 'rxjs';
import { Activity } from '../../models/vault.model';
import { ActivitiesService } from './services/activities.service';
import { CreateActivityAction } from './vault.actions';

interface VaultStateModel {
  activities: Activity[];
}

@State<VaultStateModel>({
  name: 'vault',
  defaults: {
    activities: [],
  },
})
@Injectable()
export class VaultState {
  @Selector()
  static activities(state: VaultStateModel): Activity[] {
    return state.activities;
  }

  constructor(private activitiesService: ActivitiesService) {}

  @Action(CreateActivityAction)
  createActivity(
    ctx: StateContext<VaultStateModel>,
    action: CreateActivityAction
  ) {
    return from(this.activitiesService.createActivity(action.activity)).pipe(
      catchError((error) => {
        console.error('Error creating activity:', error);
        return throwError(() => error);
      })
    );
  }
}

import { Injectable } from '@angular/core';
import { State, Selector, Action, StateContext } from '@ngxs/store';
import { catchError, throwError, from, tap } from 'rxjs';
import {
  Activity,
  ActivitySubscriptionSession,
} from '../../models/vault.model';
import { ActivitiesService } from './services/activities.service';
import {
  CreateActivityAction,
  FetchActivitiesAction,
  FetchActivityByIdAction,
  FetchActivitySubscriptionSessionsAction,
} from './vault.actions';

interface VaultStateModel {
  activities: Activity[];
  selectedActivity: Activity;
  selectedActivitySubscriptionSessions: ActivitySubscriptionSession[];
}

@State<VaultStateModel>({
  name: 'vault',
  defaults: {
    activities: [],
    selectedActivity: {
      activityName: '',
      activityDescription: '',
      activityDifficulty: '',
      activityTasks: [],
      activityId: '',
      activitySubscribersCount: 0,
    },
    selectedActivitySubscriptionSessions: [],
  },
})
@Injectable()
export class VaultState {
  @Selector()
  static activities(state: VaultStateModel): Activity[] {
    return state.activities;
  }

  @Selector()
  static selectedActivity(state: VaultStateModel): Activity | null {
    return state.selectedActivity;
  }

  @Selector()
  static selectedActivitySubscriptionSessions(
    state: VaultStateModel
  ): ActivitySubscriptionSession[] {
    return state.selectedActivitySubscriptionSessions;
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

  @Action(FetchActivitiesAction)
  fetchActivities(ctx: StateContext<VaultStateModel>) {
    return this.activitiesService.getActivities().pipe(
      tap((activities) => {
        ctx.patchState({ activities });
      }),
      catchError((error) => {
        console.error('Error fetching activities:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(FetchActivityByIdAction)
  fetchActivityById(
    ctx: StateContext<VaultStateModel>,
    action: FetchActivityByIdAction
  ) {
    return this.activitiesService.getActivityById(action.activityId).pipe(
      tap((activity) => {
        ctx.patchState({ selectedActivity: activity });
      }),
      catchError((error) => {
        console.error('Error fetching activity by id:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(FetchActivitySubscriptionSessionsAction)
  fetchActivitySubscriptionSessions(
    ctx: StateContext<VaultStateModel>,
    action: FetchActivitySubscriptionSessionsAction
  ) {
    return this.activitiesService
      .getActivitySubscriptionSessions(action.activityId)
      .pipe(
        tap((sessions) => {
          ctx.patchState({ selectedActivitySubscriptionSessions: sessions });
        }),
        catchError((error) => {
          console.error(
            'Error fetching activity subscription sessions:',
            error
          );
          return throwError(() => error);
        })
      );
  }
}

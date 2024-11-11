import { Injectable } from '@angular/core';
import { State, Selector, Action, StateContext } from '@ngxs/store';
import { catchError, throwError, from, tap } from 'rxjs';
import {
  Activity,
  ActivitySubscriptionSession,
  ActivityTask,
} from '../../models/vault.model';
import { ActivitiesService } from './services/activities.service';
import {
  CreateActivityAction,
  FetchActivitiesAction,
  FetchActivityByIdAction,
  FetchActivitySubscriptionSessionsAction,
  UpdateActivityAction,
  UpdateActivityTasksAction,
  FetchActivityTasksAction,
  FetchActivityTaskByIdAction,
  DeleteActivityTaskAction,
} from './vault.actions';

interface VaultStateModel {
  activities: Activity[];
  selectedActivity: Activity;
  selectedActivitySubscriptionSessions: ActivitySubscriptionSession[];
  selectedActivityTasks: ActivityTask[];
  selectedTask: ActivityTask | null;
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
    selectedActivityTasks: [],
    selectedTask: null,
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

  @Selector()
  static selectedActivityTasks(state: VaultStateModel): ActivityTask[] {
    return state.selectedActivityTasks;
  }

  @Selector()
  static selectedTask(state: VaultStateModel): ActivityTask | null {
    return state.selectedTask;
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

  @Action(UpdateActivityAction)
  updateActivity(
    ctx: StateContext<VaultStateModel>,
    action: UpdateActivityAction
  ) {
    return from(this.activitiesService.updateActivity(action.activity)).pipe(
      catchError((error) => {
        console.error('Error updating activity:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(UpdateActivityTasksAction)
  updateActivityTasks(
    ctx: StateContext<VaultStateModel>,
    action: UpdateActivityTasksAction
  ) {
    return from(
      this.activitiesService.updateActivityTask(
        action.activityId,
        action.tasks[0]
      )
    ).pipe(
      tap((updatedTask) => {
        const state = ctx.getState();
        const existingTasks = state.selectedActivity.activityTasks;
        const taskIndex = existingTasks.findIndex(
          (task) => task.taskId === updatedTask.taskId
        );
        if (taskIndex > -1) {
          existingTasks[taskIndex] = updatedTask;
        }
        const selectedActivity = {
          ...state.selectedActivity,
          activityTasks: [...existingTasks],
        };
        ctx.patchState({ selectedActivity });
      }),
      catchError((error) => {
        console.error('Error updating activity task:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(FetchActivityTasksAction)
  fetchActivityTasks(
    ctx: StateContext<VaultStateModel>,
    action: FetchActivityTasksAction
  ) {
    return this.activitiesService.getActivityTasks(action.activityId).pipe(
      tap((tasks) => {
        ctx.patchState({ selectedActivityTasks: tasks });
      }),
      catchError((error) => {
        console.error('Error fetching activity tasks:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(FetchActivityTaskByIdAction)
  fetchActivityTaskById(
    ctx: StateContext<VaultStateModel>,
    action: FetchActivityTaskByIdAction
  ) {
    return this.activitiesService
      .getActivityTaskById(action.activityId, action.taskId)
      .pipe(
        tap((task) => {
          ctx.patchState({ selectedTask: task });
        }),
        catchError((error) => {
          console.error('Error fetching activity task by id:', error);
          return throwError(() => error);
        })
      );
  }

  @Action(DeleteActivityTaskAction)
  deleteActivityTask(
    ctx: StateContext<VaultStateModel>,
    action: DeleteActivityTaskAction
  ) {
    return from(
      this.activitiesService.deleteActivityTask(
        action.activityId,
        action.taskId
      )
    ).pipe(
      tap(() => {
        const state = ctx.getState();
        const updatedTasks = state.selectedActivity.activityTasks.map((task) =>
          task.taskId === action.taskId ? { ...task, isDeleted: true } : task
        );
        ctx.patchState({
          selectedActivity: {
            ...state.selectedActivity,
            activityTasks: updatedTasks,
          },
        });
      }),
      catchError((error) => {
        console.error('Error deleting activity task:', error);
        return throwError(() => error);
      })
    );
  }
}

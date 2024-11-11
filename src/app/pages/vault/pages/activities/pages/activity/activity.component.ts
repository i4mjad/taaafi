import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { Store, Select } from '@ngxs/store';
import { Observable } from 'rxjs';
import { MatDialog } from '@angular/material/dialog';
import {
  Activity,
  ActivitySubscriptionSession,
} from '../../../../../../models/vault.model';
import { VaultState } from '../../../../../../state/vault/vault.store';
import {
  FetchActivityByIdAction,
  FetchActivitySubscriptionSessionsAction,
  UpdateActivityAction,
  UpdateActivityTasksAction,
  DeleteActivityTaskAction,
} from '../../../../../../state/vault/vault.actions';
import { UpdateActivityComponent } from './dialogs/update-activity/update-activity.component';
import { UpdateActivityTaskComponent } from './dialogs/update-activity-task/update-activity-task.component';
import { DeleteTaskComponent } from './dialogs/delete-task/delete-task.component';

@Component({
  selector: 'app-activity',
  templateUrl: './activity.component.html',
  styleUrls: ['./activity.component.scss'],
})
export class ActivityComponent implements OnInit {
  activityId: string;
  @Select(VaultState.selectedActivity) activity$: Observable<Activity>;
  @Select(VaultState.selectedActivitySubscriptionSessions)
  activitySubscriptionSessions$: Observable<ActivitySubscriptionSession[]>;
  activity: Activity | null = null;
  sessionsTableDisplayedColumns: string[] = [
    'sessionId',
    'userUid',
    'sessionDate',
    'sessionDuration',
  ];
  tasksTableDisplayedColumns: string[] = [
    'taskName',
    'taskDescription',
    'taskFrequency',
    'action',
  ];
  activitySubscriptionSessions: ActivitySubscriptionSession[] = [];

  constructor(
    private route: ActivatedRoute,
    private store: Store,
    private dialog: MatDialog
  ) {
    this.activityId = this.route.snapshot.paramMap.get('id')!;
  }

  ngOnInit(): void {
    this.store.dispatch(new FetchActivityByIdAction(this.activityId));
    this.store.dispatch(
      new FetchActivitySubscriptionSessionsAction(this.activityId)
    );
    this.activity$.subscribe((activity) => {
      if (activity) {
        this.activity = activity;
      }
    });
    this.activitySubscriptionSessions$.subscribe((sessions) => {
      this.activitySubscriptionSessions = sessions;
    });
  }

  openUpdateActivityDialog(): void {
    const dialogRef = this.dialog.open(UpdateActivityComponent, {
      data: { activity: this.activity },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.store.dispatch(new UpdateActivityAction(result));
      }
    });
  }

  openUpdateActivityTasksDialog(taskId: string): void {
    const dialogRef = this.dialog.open(UpdateActivityTaskComponent, {
      data: { activityId: this.activityId, taskId },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.store.dispatch(
          new UpdateActivityTasksAction(this.activityId, result)
        );
      }
    });
  }

  openDeleteTaskDialog(taskId: string): void {
    const dialogRef = this.dialog.open(DeleteTaskComponent, {
      data: { taskId },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.store.dispatch(
          new DeleteActivityTaskAction(this.activityId, taskId)
        );
      }
    });
  }
}

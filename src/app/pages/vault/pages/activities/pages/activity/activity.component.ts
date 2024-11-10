import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { Store, Select } from '@ngxs/store';
import { Observable } from 'rxjs';
import {
  Activity,
  ActivitySubscriptionSession,
} from '../../../../../../models/vault.model';
import { VaultState } from '../../../../../../state/vault/vault.store';
import {
  FetchActivityByIdAction,
  FetchActivitySubscriptionSessionsAction,
} from '../../../../../../state/vault/vault.actions';

@Component({
  selector: 'app-activity',
  templateUrl: './activity.component.html',
  styleUrls: ['./activity.component.scss'],
})
export class ActivityComponent implements OnInit {
  activityId: string;
  @Select(VaultState.selectedActivity) activity$: Observable<Activity | null>;
  @Select(VaultState.selectedActivitySubscriptionSessions)
  activitySubscriptionSessions$: Observable<ActivitySubscriptionSession[]>;
  activity: Activity | null = null;
  displayedColumns: string[] = [
    'sessionId',
    'userUid',
    'sessionDate',
    'sessionDuration',
  ];
  activitySubscriptionSessions: ActivitySubscriptionSession[] = [];

  constructor(private route: ActivatedRoute, private store: Store) {
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
}

import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import {
  Activity,
  ActivitySubscriptionSession,
  fakeActivities,
} from '../../../../../../models/vault.model';

@Component({
  selector: 'app-activity',
  templateUrl: './activity.component.html',
  styleUrl: './activity.component.scss',
})
export class ActivityComponent implements OnInit {
  activityId: string;
  activity: Activity;
  displayedColumns: string[] = ['sessionId', 'sessionDate', 'sessionDuration'];
  activitySubscriptionSessions: ActivitySubscriptionSession[] = [];
  constructor(private route: ActivatedRoute, private router: Router) {
    if (this.route.snapshot.paramMap.get('id')) {
      this.activityId = this.route.snapshot.paramMap.get('id')!;
    }
  }
  ngOnInit(): void {
    this.activity = fakeActivities.find(
      (activity) => activity.activityId === this.activityId
    )!;
  }
}

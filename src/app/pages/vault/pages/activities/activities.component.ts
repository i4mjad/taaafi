import { Component } from '@angular/core';
import { Activity, fakeActivities } from '../../../../models/vault.model';

@Component({
  selector: 'app-activities',
  templateUrl: './activities.component.html',
  styleUrl: './activities.component.scss',
})
export class ActivitiesComponent {
  displayedColumns: string[] = [
    'id',
    'activityName',
    'activityDescription',
    'activityTasksCount',
    'activitySubscribersCount',
    'actions',
  ];
  dataSource: Activity[] = fakeActivities;
}

import { Component, inject, OnInit } from '@angular/core';
import { Store, Select } from '@ngxs/store';
import { Observable } from 'rxjs';
import { Activity } from '../../../../models/vault.model';
import { VaultState } from '../../../../state/vault/vault.store';
import { FetchActivitiesAction } from '../../../../state/vault/vault.actions';

@Component({
  selector: 'app-activities',
  templateUrl: './activities.component.html',
  styleUrls: ['./activities.component.scss'],
})
export class ActivitiesComponent implements OnInit {
  displayedColumns: string[] = [
    'id',
    'activityName',
    'activityDescription',
    'activityDifficulty',
    'activitySubscribersCount',
    'actions',
  ];

  activities$: Observable<Activity[]> = inject(Store).select(
    VaultState.activities
  );

  activities: Activity[];
  constructor(private store: Store) {}

  ngOnInit(): void {
    this.store.dispatch(new FetchActivitiesAction());
    this.activities$.subscribe((data) => {
      console.log(data);
      if (data.length > 0) {
        this.activities = data;
      }
    });
  }
}

import { Injectable } from '@angular/core';
import { Observable, from } from 'rxjs';
import { ActivityDataModel } from '../../../models/vault.model';
import {
  AngularFirestore,
  AngularFirestoreCollection,
} from '@angular/fire/compat/firestore';

@Injectable({
  providedIn: 'root',
})
export class ActivitiesService {
  private contentTypesCollectionsRef: AngularFirestoreCollection<ActivityDataModel>;

  constructor(private firestore: AngularFirestore) {
    this.contentTypesCollectionsRef =
      this.firestore.collection<ActivityDataModel>('activities');
  }

  async createActivity(activity: ActivityDataModel): Promise<void> {
    const activityDocRef = this.contentTypesCollectionsRef.doc();

    await activityDocRef.set({
      activityName: activity.activityName,
      activityDifficulty: activity.activityDifficulty,
      activityDescription: activity.activityDescription,
      createdAt: new Date() ?? new Date(),
    });

    if (activity.activityTasks) {
      const tasksPromises = activity.activityTasks.map((task) => {
        const taskRef = activityDocRef
          .collection('activityTasks')
          .doc(task.taskId);
        return taskRef.set(task);
      });
      await Promise.all(tasksPromises);
    }
  }
}

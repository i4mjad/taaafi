import { Injectable } from '@angular/core';
import { Observable, from } from 'rxjs';
import {
  Activity,
  ActivityDataModel,
  ActivitySubscriptionSession,
} from '../../../models/vault.model';
import {
  AngularFirestore,
  AngularFirestoreCollection,
} from '@angular/fire/compat/firestore';
import { map, switchMap } from 'rxjs/operators';
import { Timestamp } from 'firebase/firestore';

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

  getActivities(): Observable<Activity[]> {
    return this.contentTypesCollectionsRef
      .snapshotChanges()
      .pipe(
        switchMap((actions) =>
          from(Promise.all(actions.map((a) => this.mapActivity(a))))
        )
      );
  }

  getActivityById(activityId: string): Observable<Activity> {
    const activityDocRef = this.contentTypesCollectionsRef.doc(activityId);
    return from(activityDocRef.get()).pipe(
      switchMap(async (doc) => {
        if (doc.exists) {
          const data = doc.data() as ActivityDataModel;
          const activitySubscriptionSessionsRef = doc.ref.collection(
            'activitySubscriptionSessions'
          );
          const activitySubscriptionSessionsSnapshot =
            await activitySubscriptionSessionsRef.get();
          const activitySubscribersCount =
            activitySubscriptionSessionsSnapshot.size;

          return {
            activityId: doc.id,
            activityName: data.activityName,
            activityDifficulty: data.activityDifficulty,
            activityDescription: data.activityDescription,
            activitySubscribersCount: activitySubscribersCount,
            activityTasks: data.activityTasks || [],
            createdAt:
              data.createdAt instanceof Timestamp
                ? data.createdAt.toDate()
                : new Date(),
          } as Activity;
        } else {
          throw new Error('Activity not found');
        }
      })
    );
  }

  getActivitySubscriptionSessions(
    activityId: string
  ): Observable<ActivitySubscriptionSession[]> {
    const activityDocRef = this.contentTypesCollectionsRef.doc(activityId);
    const activitySubscriptionSessionsRef = activityDocRef.collection(
      'activitySubscriptionSessions'
    );
    return activitySubscriptionSessionsRef.snapshotChanges().pipe(
      map((actions) =>
        actions.map((a) => {
          const data = a.payload.doc.data() as ActivitySubscriptionSession;
          const id = a.payload.doc.id;
          return { ...data, activitySubscriptionSessionId: id };
        })
      )
    );
  }

  private async mapActivity(a: any): Promise<Activity> {
    const data = a.payload.doc.data() as ActivityDataModel;
    const id = a.payload.doc.id;
    const activitySubscriptionSessionsRef = a.payload.doc.ref.collection(
      'activitySubscriptionSessions'
    );
    const activitySubscriptionSessionsSnapshot =
      await activitySubscriptionSessionsRef.get();
    const activitySubscribersCount = activitySubscriptionSessionsSnapshot.size;

    return {
      activityId: id,
      activityName: data.activityName,
      activityDifficulty: data.activityDifficulty,
      activityDescription: data.activityDescription,
      activitySubscribersCount: activitySubscribersCount,
      activityTasks: data.activityTasks || [],
      createdAt:
        data.createdAt instanceof Timestamp
          ? data.createdAt.toDate()
          : Timestamp.now().toDate(),
    } as Activity;
  }
}

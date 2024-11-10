import { Component, Inject, OnInit } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { Store, Select } from '@ngxs/store';
import { FetchActivityTasksAction } from '../../../../../../../../state/vault/vault.actions';
import { VaultState } from '../../../../../../../../state/vault/vault.store';
import { Observable } from 'rxjs';
import {
  ActivityTask,
  TaskFrequency,
} from '../../../../../../../../models/vault.model';

@Component({
  selector: 'app-update-activity-tasks',
  templateUrl: './update-activity-tasks.component.html',
  styleUrls: ['./update-activity-tasks.component.scss'],
})
export class UpdateActivityTasksComponent implements OnInit {
  tasksForm: FormGroup;
  taskFrequencies = Object.values(TaskFrequency);
  @Select(VaultState.selectedActivityTasks) tasks$: Observable<ActivityTask[]>;

  constructor(
    private fb: FormBuilder,
    private dialogRef: MatDialogRef<UpdateActivityTasksComponent>,
    private store: Store,
    @Inject(MAT_DIALOG_DATA) public data: { activityId: string }
  ) {
    this.tasksForm = this.fb.group({
      tasks: this.fb.array([]),
    });
  }

  ngOnInit(): void {
    this.store.dispatch(new FetchActivityTasksAction(this.data.activityId));
    this.tasks$.subscribe((tasks) => {
      tasks.forEach((task) => this.addTask(task));
    });
  }

  get tasks(): FormArray {
    return this.tasksForm.get('tasks') as FormArray;
  }

  addTask(task?: ActivityTask): void {
    const taskGroup = this.fb.group({
      taskName: [task?.taskName || '', Validators.required],
      taskDescription: [task?.taskDescription || '', Validators.required],
      taskFrequency: [task?.taskFrequency || '', Validators.required],
    });
    this.tasks.push(taskGroup);
  }

  removeTask(index: number): void {
    this.tasks.removeAt(index);
  }

  onSubmit(): void {
    if (this.tasksForm.valid) {
      this.dialogRef.close(this.tasksForm.value.tasks);
    }
  }

  onCancel(): void {
    this.dialogRef.close();
  }
}

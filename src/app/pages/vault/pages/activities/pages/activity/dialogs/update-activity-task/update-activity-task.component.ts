import { Component, Inject, OnInit } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Store, Select } from '@ngxs/store';
import { FetchActivityTaskByIdAction } from '../../../../../../../../state/vault/vault.actions';
import { VaultState } from '../../../../../../../../state/vault/vault.store';
import { Observable } from 'rxjs';
import {
  ActivityTask,
  TaskFrequency,
} from '../../../../../../../../models/vault.model';

@Component({
  selector: 'app-update-activity-task',
  templateUrl: './update-activity-task.component.html',
  styleUrls: ['./update-activity-task.component.scss'],
})
export class UpdateActivityTaskComponent implements OnInit {
  tasksForm: FormGroup;
  taskFrequencies = Object.values(TaskFrequency);
  @Select(VaultState.selectedTask) task$: Observable<ActivityTask | null>;

  constructor(
    private fb: FormBuilder,
    private dialogRef: MatDialogRef<UpdateActivityTaskComponent>,
    private store: Store,
    @Inject(MAT_DIALOG_DATA) public data: { activityId: string; taskId: string }
  ) {
    this.tasksForm = this.fb.group({
      taskName: ['', Validators.required],
      taskDescription: ['', Validators.required],
      taskFrequency: ['', Validators.required],
    });
  }

  ngOnInit(): void {
    this.store.dispatch(
      new FetchActivityTaskByIdAction(this.data.activityId, this.data.taskId)
    );
    this.task$.subscribe((task) => {
      if (task) {
        this.tasksForm.patchValue(task);
      }
    });
  }

  onSubmit(): void {
    if (this.tasksForm.valid) {
      const updatedTask: ActivityTask = {
        taskId: this.data.taskId,
        ...this.tasksForm.value,
      };
      this.dialogRef.close([updatedTask]);
    }
  }

  onCancel(): void {
    this.dialogRef.close();
  }

  onClose(): void {
    this.dialogRef.close();
  }
}

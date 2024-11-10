import { Component, Inject } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import {
  Activity,
  ActivityDataModel,
} from '../../../../../../../../models/vault.model';

@Component({
  selector: 'app-update-activity',
  templateUrl: './update-activity.component.html',
  styleUrls: ['./update-activity.component.scss'],
})
export class UpdateActivityComponent {
  activityForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    private dialogRef: MatDialogRef<UpdateActivityComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { activity: Activity }
  ) {
    this.activityForm = this.fb.group({
      activityName: [data.activity.activityName, Validators.required],
      activityDescription: [
        data.activity.activityDescription,
        Validators.required,
      ],
    });
  }

  onSubmit(): void {
    if (this.activityForm.valid) {
      this.dialogRef.close({
        ...this.data.activity,
        ...this.activityForm.value,
      });
    }
  }

  onCancel(): void {
    this.dialogRef.close();
  }
}

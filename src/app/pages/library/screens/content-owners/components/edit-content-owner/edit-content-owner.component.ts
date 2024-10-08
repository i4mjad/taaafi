import { Component, Inject } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { Store } from '@ngxs/store';
import { ContentOwner } from '../../../../../../models/app.model';
import { UpdateContentOwnerAction } from '../../../../../../state/app.actions';

@Component({
  selector: 'app-edit-content-owner',
  templateUrl: './edit-content-owner.component.html',
  styleUrl: './edit-content-owner.component.scss',
})
export class EditContentOwnerComponent {
  contentOwnerForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    private store: Store,
    private dialogRef: MatDialogRef<EditContentOwnerComponent>,
    @Inject(MAT_DIALOG_DATA) public data: ContentOwner // The content type object passed to the dialog
  ) {}

  ngOnInit(): void {
    this.contentOwnerForm = this.fb.group({
      ownerName: [this.data.ownerName, [Validators.required]],
      ownerSource: [this.data.ownerSource, [Validators.required]],
      isActive: [this.data.isActive],
    });
  }

  onSubmit(): void {
    if (this.contentOwnerForm.valid) {
      const { ownerName, ownerSource, isActive } = this.contentOwnerForm.value;
      const updatedContentOwner: ContentOwner = {
        id: this.data.id,
        ownerName,
        ownerSource,
        isActive,
      };

      this.store.dispatch(new UpdateContentOwnerAction(updatedContentOwner));
      this.dialogRef.close();
    }
  }

  onCancel(): void {
    this.dialogRef.close();
  }
}

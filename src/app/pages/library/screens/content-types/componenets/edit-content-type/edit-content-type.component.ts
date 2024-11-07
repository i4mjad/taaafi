import { Component, Inject } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { Store } from '@ngxs/store';
import { ContentType } from '../../../../../../models/library.model';
import { UpdateContentTypeAction } from '../../../../../../state/library/library.actions';

@Component({
  selector: 'app-edit-content-type',
  templateUrl: './edit-content-type.component.html',
  styleUrl: './edit-content-type.component.scss',
})
export class EditContentTypeComponent {
  contentTypeForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    private store: Store,
    private dialogRef: MatDialogRef<EditContentTypeComponent>,
    @Inject(MAT_DIALOG_DATA) public data: ContentType // The content type object passed to the dialog
  ) {}

  ngOnInit(): void {
    this.contentTypeForm = this.fb.group({
      contentTypeName: [this.data.contentTypeName, [Validators.required]],
      isActive: [this.data.isActive],
    });
  }

  onSubmit(): void {
    if (this.contentTypeForm.valid) {
      const { contentTypeName, isActive } = this.contentTypeForm.value;
      const updatedContentType: ContentType = {
        id: this.data.id,
        contentTypeName,
        isActive,
      };

      this.store.dispatch(new UpdateContentTypeAction(updatedContentType));
      this.dialogRef.close();
    }
  }

  onCancel(): void {
    this.dialogRef.close();
  }
}

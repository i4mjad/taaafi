import { Component, Inject } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { Store } from '@ngxs/store';
import { ContentType } from '../../../../../../models/app.model';
import { UpdateContentTypeAction } from '../../../../../../state/app.actions';

@Component({
  selector: 'app-edit-content-category',
  templateUrl: './edit-content-category.component.html',
  styleUrl: './edit-content-category.component.scss',
})
export class EditContentCategoryComponent {
  contentTypeForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    private store: Store,
    private dialogRef: MatDialogRef<EditContentCategoryComponent>,
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

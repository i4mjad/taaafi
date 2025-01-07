import { Component, Inject } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { Store } from '@ngxs/store';
import { ContentCategory } from '../../../../../../models/library.model';
import { UpdateContentCategoryAction } from '../../../../../../state/library/library.actions';

@Component({
  selector: 'app-edit-content-category',
  templateUrl: './edit-content-category.component.html',
  styleUrl: './edit-content-category.component.scss',
})
export class EditContentCategoryComponent {
  contentCategoryForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    private store: Store,
    private dialogRef: MatDialogRef<EditContentCategoryComponent>,
    @Inject(MAT_DIALOG_DATA) public data: ContentCategory // The content type object passed to the dialog
  ) {}

  ngOnInit(): void {
    this.contentCategoryForm = this.fb.group({
      categoryName: [this.data.categoryName, [Validators.required]],
      isActive: [this.data.isActive],
    });
  }

  onSubmit(): void {
    if (this.contentCategoryForm.valid) {
      const { categoryName, contentCategoryIconName, isActive } =
        this.contentCategoryForm.value;
      const updatedContentCategory: ContentCategory = {
        id: this.data.id,
        categoryName,
        contentCategoryIconName,
        isActive,
      };

      this.store.dispatch(
        new UpdateContentCategoryAction(updatedContentCategory)
      );
      this.dialogRef.close();
    }
  }

  onCancel(): void {
    this.dialogRef.close();
  }
}

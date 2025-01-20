import { Component, inject, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MatBottomSheetRef } from '@angular/material/bottom-sheet';
import { Store } from '@ngxs/store';
import { CreateContentCategoryAction } from '../../../../../../state/library/library.actions';

@Component({
  selector: 'app-add-new-content-category',
  templateUrl: './add-new-content-category.component.html',
  styleUrl: './add-new-content-category.component.scss',
})
export class AddNewContentCategoryComponent implements OnInit {
  private _bottomSheetRef =
    inject<MatBottomSheetRef<AddNewContentCategoryComponent>>(
      MatBottomSheetRef
    );

  contentTypeForm: FormGroup;

  constructor(private fb: FormBuilder, private store: Store) {}

  ngOnInit(): void {
    this.contentTypeForm = this.fb.group({
      categoryName: ['', [Validators.required]],
      contentCategoryIconName: ['', [Validators.required]], // New form control
      isActive: [false],
    });
  }

  onSubmit(): void {
    if (this.contentTypeForm.valid) {
      const { categoryName, contentCategoryIconName, isActive } =
        this.contentTypeForm.value;

      this.store.dispatch(
        new CreateContentCategoryAction(
          categoryName,
          contentCategoryIconName,
          isActive
        )
      );
      this._bottomSheetRef.dismiss();
    }
  }
  openLink(event: MouseEvent): void {
    this._bottomSheetRef.dismiss();
    event.preventDefault();
  }
}

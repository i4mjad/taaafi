import { Component, inject, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MatBottomSheetRef } from '@angular/material/bottom-sheet';
import { Store } from '@ngxs/store';
import { CreateContentCategoryAction } from '../../../../../../state/app.actions';

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
      contentTypeName: ['', [Validators.required]],
      isActive: [false],
    });
  }

  onSubmit(): void {
    if (this.contentTypeForm.valid) {
      const { contentTypeName, isActive } = this.contentTypeForm.value;

      this.store.dispatch(
        new CreateContentCategoryAction(contentTypeName, isActive)
      );
      this._bottomSheetRef.dismiss();
    }
  }
  openLink(event: MouseEvent): void {
    this._bottomSheetRef.dismiss();
    event.preventDefault();
  }
}

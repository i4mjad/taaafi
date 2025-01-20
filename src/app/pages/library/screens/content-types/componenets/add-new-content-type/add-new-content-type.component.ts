import { Component, inject } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MatBottomSheetRef } from '@angular/material/bottom-sheet';
import { Store } from '@ngxs/store';
import { CreateContentTypeAction } from '../../../../../../state/library/library.actions';

@Component({
  selector: 'app-add-new-content-type',
  templateUrl: './add-new-content-type.component.html',
  styleUrl: './add-new-content-type.component.scss',
})
export class AddNewContentTypeComponent {
  private _bottomSheetRef =
    inject<MatBottomSheetRef<AddNewContentTypeComponent>>(MatBottomSheetRef);

  contentTypeForm: FormGroup;

  constructor(private fb: FormBuilder, private store: Store) {}

  ngOnInit(): void {
    this.contentTypeForm = this.fb.group({
      contentTypeName: ['', [Validators.required]],
      isActive: [false],
      contentTypeIconName: ['', [Validators.required]],
    });
  }

  onSubmit(): void {
    if (this.contentTypeForm.valid) {
      const { contentTypeName, isActive, contentTypeIconName } =
        this.contentTypeForm.value;

      this.store.dispatch(
        new CreateContentTypeAction(
          contentTypeName,
          contentTypeIconName,
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

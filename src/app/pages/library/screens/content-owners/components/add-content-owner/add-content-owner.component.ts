import { Component, inject } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Store } from '@ngxs/store';
import { CreateContentOwnerAction } from '../../../../../../state/app.actions';
import { MatBottomSheetRef } from '@angular/material/bottom-sheet';

@Component({
  selector: 'app-add-content-owner',
  templateUrl: './add-content-owner.component.html',
  styleUrl: './add-content-owner.component.scss',
})
export class AddContentOwnerComponent {
  private _bottomSheetRef =
    inject<MatBottomSheetRef<AddContentOwnerComponent>>(MatBottomSheetRef);
  form: FormGroup;

  constructor(private fb: FormBuilder, private store: Store) {
    this.form = this.fb.group({
      ownerName: ['', Validators.required],
      ownerSource: ['', Validators.required],
      isActive: [true],
    });
  }

  onSubmit(): void {
    if (this.form.valid) {
      const { ownerName, ownerSource, isActive } = this.form.value;
      this.store.dispatch(
        new CreateContentOwnerAction(ownerName, ownerSource, isActive)
      );
      this._bottomSheetRef.dismiss();
    }
  }
}

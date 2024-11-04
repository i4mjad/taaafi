import { Component, inject, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MatBottomSheetRef } from '@angular/material/bottom-sheet';
import { Store } from '@ngxs/store';
import {
  ContentType,
  ContentCategory,
  ContentOwner,
} from '../../../../../../models/app.model';
import { Observable } from 'rxjs';
import {
  GetContentTypesAction,
  GetContentCategoriesAction,
  GetContentOwnersAction,
  CreateContentAction,
} from '../../../../../../state/library/library.actions';
import { AppState } from '../../../../../../state/library/library.store';

@Component({
  selector: 'app-add-new-content',
  templateUrl: './add-new-content.component.html',
  styleUrl: './add-new-content.component.scss',
})
export class AddNewContentComponent implements OnInit {
  contentTypes$: Observable<ContentType[]> = inject(Store).select(
    AppState.contentTypes
  );
  contentCategories$: Observable<ContentCategory[]> = inject(Store).select(
    AppState.contentCategories
  );
  contentOwners$: Observable<ContentOwner[]> = inject(Store).select(
    AppState.contentOwners
  );

  contentForm: FormGroup;
  contentTypes: ContentType[] = [];
  contentCategories: ContentCategory[] = [];
  contentOwners: ContentOwner[] = [];

  constructor(
    private fb: FormBuilder,
    private store: Store,
    private _bottomSheetRef: MatBottomSheetRef<AddNewContentComponent>
  ) {}

  ngOnInit(): void {
    // Initialize the form with the required controls
    this.contentForm = this.fb.group({
      contentName: ['', [Validators.required]],
      contentLanguage: ['', [Validators.required]],
      contentTypeId: ['', [Validators.required]],
      contentCategoryId: ['', [Validators.required]],
      contentOwnerId: ['', [Validators.required]],
      contentLink: ['', [Validators.required]],
      isActive: [false],
    });

    // Load content types, categories, and owners to populate the dropdowns
    this.loadContentTypes();
    this.loadContentCategories();
    this.loadContentOwners();
  }

  // Method to load content types from Firestore
  loadContentTypes() {
    this.store.dispatch(new GetContentTypesAction());
    this.contentTypes$.subscribe((data) => {
      if (data.length > 0) {
        this.contentTypes = data;
      }
    });
  }

  // Method to load content categories from Firestore
  loadContentCategories() {
    this.store.dispatch(new GetContentCategoriesAction());
    this.contentCategories$.subscribe((data) => {
      if (data.length > 0) {
        this.contentCategories = data;
      }
    });
  }

  // Method to load content owners from Firestore
  loadContentOwners() {
    this.store.dispatch(new GetContentOwnersAction());
    this.contentOwners$.subscribe((data) => {
      if (data.length > 0) {
        this.contentOwners = data;
      }
    });
  }

  // Handle form submission
  onSubmit(): void {
    if (this.contentForm.valid) {
      const {
        contentName,
        contentTypeId,
        contentCategoryId,
        contentOwnerId,
        contentLanguage,
        contentLink,
        isActive,
      } = this.contentForm.value;

      // Dispatch CreateContentAction with the form values
      this.store.dispatch(
        new CreateContentAction(
          contentName,
          contentTypeId,
          contentCategoryId,
          contentOwnerId,
          contentLink,
          contentLanguage,
          '',
          isActive
        )
      );

      this._bottomSheetRef.dismiss();
    }
  }
}

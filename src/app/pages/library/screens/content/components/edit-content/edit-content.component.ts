import { Component, Inject, OnInit } from '@angular/core';

import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { Store } from '@ngxs/store';
import {
  ContentType,
  ContentCategory,
  ContentOwner,
  Content,
  ContentDateModel,
} from '../../../../../../models/library.model';
import {
  GetContentTypesAction,
  GetContentCategoriesAction,
  GetContentOwnersAction,
  UpdateContentAction,
} from '../../../../../../state/library/library.actions';
import { LibraryState } from '../../../../../../state/library/library.store';

@Component({
  selector: 'app-edit-content',
  templateUrl: './edit-content.component.html',
  styleUrl: './edit-content.component.scss',
})
export class EditContentComponent implements OnInit {
  contentForm: FormGroup;
  contentTypes: ContentType[] = [];
  contentCategories: ContentCategory[] = [];
  contentOwners: ContentOwner[] = [];

  constructor(
    private fb: FormBuilder,
    private store: Store,

    private dialogRef: MatDialogRef<EditContentComponent>,
    @Inject(MAT_DIALOG_DATA) public data: Content // The content object passed to the dialog
  ) {}

  ngOnInit(): void {
    // Initialize the form with the required controls
    this.contentForm = this.fb.group({
      contentName: [this.data.contentName, [Validators.required]],
      contentLanguage: [this.data.contentLanguage, [Validators.required]],
      contentTypeId: [this.data.contentType.id, [Validators.required]],
      contentCategoryId: [this.data.contentCategory.id, [Validators.required]],
      contentOwnerId: [this.data.contentOwner.id, [Validators.required]],
      contentLink: [this.data.contentLink, [Validators.required]],
      isActive: [this.data.isActive],
    });

    // Load content types, categories, and owners to populate the dropdowns
    this.loadContentTypes();
    this.loadContentCategories();
    this.loadContentOwners();
  }

  // Load content types from Firestore
  loadContentTypes() {
    this.store.dispatch(new GetContentTypesAction());
    this.store.select(LibraryState.contentTypes).subscribe((data) => {
      this.contentTypes = data;
    });
  }

  // Load content categories from Firestore
  loadContentCategories() {
    this.store.dispatch(new GetContentCategoriesAction());
    this.store.select(LibraryState.contentCategories).subscribe((data) => {
      this.contentCategories = data;
    });
  }

  // Load content owners from Firestore
  loadContentOwners() {
    this.store.dispatch(new GetContentOwnersAction());
    this.store.select(LibraryState.contentOwners).subscribe((data) => {
      this.contentOwners = data;
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
        isDeleted,
      } = this.contentForm.value;

      const contentData: ContentDateModel = {
        contentName,
        contentTypeId,
        contentLanguage,
        contentCategoryId,
        contentOwnerId,
        contentLink,
        updatedAt: new Date(), // Automatically update the timestamp
        updatedBy: '', // Set this to the current user's ID
        isActive,
        isDeleted,
      };

      // Dispatch the updated content data with the content ID
      this.store.dispatch(new UpdateContentAction(this.data.id, contentData));
      this.dialogRef.close();
    }
  }

  // Handle cancel action
  onCancel(): void {
    this.dialogRef.close();
  }
}

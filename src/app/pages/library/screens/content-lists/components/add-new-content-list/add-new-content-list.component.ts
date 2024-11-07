import { Component } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Store } from '@ngxs/store';
import { Observable } from 'rxjs';
import {
  Content,
  ContentListDataModel,
} from '../../../../../../models/library.model';

import { MatCheckboxChange } from '@angular/material/checkbox';
import { MatDialogRef } from '@angular/material/dialog';
import {
  GetContentsAction,
  CreateContentListAction,
} from '../../../../../../state/library/library.actions';
import { LibraryState } from '../../../../../../state/library/library.store';

@Component({
  selector: 'app-add-new-content-list',
  templateUrl: './add-new-content-list.component.html',
  styleUrl: './add-new-content-list.component.scss',
})
export class AddNewContentListComponent {
  contentListForm: FormGroup;
  contents$: Observable<Content[]> = this.store.select(LibraryState.content);

  allContent: Content[] = []; // Store the original content list
  filteredContent: Content[] = []; // The filtered content list
  selection: Set<string> = new Set(); // Store selected content IDs

  tableColumns: string[] = ['select', 'contentName', 'contentOwner'];

  constructor(
    private fb: FormBuilder,
    private store: Store,
    private dialogRef: MatDialogRef<AddNewContentListComponent>
  ) {}

  ngOnInit(): void {
    // Initialize the form group
    this.contentListForm = this.fb.group({
      listName: ['', [Validators.required]],
      listDescription: ['', [Validators.required]],
      isActive: [true],
      isFeatured: [false],
    });

    // Fetch available content
    this.store.dispatch(new GetContentsAction());

    // Subscribe to the content list and initialize the filtered content
    this.contents$.subscribe((contents) => {
      this.allContent = contents; // Store the full list of content
      this.filteredContent = contents; // Initially show all content
    });
  }

  // Apply a filter to search for content in the table
  applyFilter(filterValue: string) {
    filterValue = filterValue.trim().toLowerCase(); // Normalize the input
    if (filterValue) {
      // Filter the content based on the input value
      this.filteredContent = this.allContent.filter((content) =>
        content.contentName.toLowerCase().includes(filterValue)
      );
    } else {
      // If the filter is cleared, reset the filtered content to the full list
      this.filteredContent = this.allContent;
    }
  }

  // Toggle content selection
  onContentSelect(contentId: string) {
    if (this.selection.has(contentId)) {
      this.selection.delete(contentId);
    } else {
      this.selection.add(contentId);
    }
  }

  // Check if all contents are selected
  isAllSelected() {
    return this.selection.size === this.filteredContent.length;
  }

  // Check if there is partial selection (indeterminate state)
  isIndeterminate() {
    return this.selection.size > 0 && !this.isAllSelected();
  }

  // Select or deselect all contents
  toggleSelectAll(event: MatCheckboxChange) {
    const isChecked = event.checked;
    if (isChecked) {
      this.filteredContent.forEach((content) => this.selection.add(content.id));
    } else {
      this.selection.clear();
    }
  }

  // Handle form submission
  onSubmit() {
    if (this.contentListForm.valid) {
      const { listName, listDescription, isActive, isFeatured } =
        this.contentListForm.value;

      // Dispatch the action to add the new content list
      this.store.dispatch(
        new CreateContentListAction(
          listName,
          listDescription,
          Array.from(this.selection), // Convert Set to Array
          isActive,
          isFeatured
        )
      );

      this.dialogRef.close();
    }
  }
}

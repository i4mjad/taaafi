import { Component, Inject } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MatCheckboxChange } from '@angular/material/checkbox';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { Store } from '@ngxs/store';
import { Observable } from 'rxjs';
import { Content, ContentList } from '../../../../../../models/library.model';
import {
  GetActiveContentAction,
  GetContentListByIdAction,
  UpdateContentListAction,
} from '../../../../../../state/library/library.actions';
import { LibraryState } from '../../../../../../state/library/library.store';

@Component({
  selector: 'app-edit-content-list',
  templateUrl: './edit-content-list.component.html',
  styleUrls: ['./edit-content-list.component.scss'],
})
export class EditContentListComponent {
  contentListForm: FormGroup;
  contents$: Observable<Content[]> = this.store.select(
    LibraryState.activeContent
  );
  selectedContentList$: Observable<ContentList> = this.store.select(
    LibraryState.selectedContentList
  );

  allContent: Content[] = [];
  selection: Set<string> = new Set();

  tableColumns: string[] = ['select', 'contentName', 'contentOwner'];

  constructor(
    private fb: FormBuilder,
    private store: Store,
    private dialogRef: MatDialogRef<EditContentListComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { id: string }
  ) {}

  ngOnInit(): void {
    this.contentListForm = this.fb.group({
      listName: ['', [Validators.required]],
      listDescription: ['', [Validators.required]],
      isActive: [false],
      isFeatured: [false],
      contentListIconName: ['', [Validators.required]], // New field added
    });

    this.store.dispatch(new GetActiveContentAction());

    this.store.dispatch(new GetContentListByIdAction(this.data.id));

    this.selectedContentList$.subscribe((contentList) => {
      if (contentList) {
        this.contentListForm.patchValue({
          listName: contentList.listName,
          listDescription: contentList.listDescription,
          isActive: contentList.isActive,
          isFeatured: contentList.isFeatured,
          contentListIconName: contentList.contentListIconName, // New field added
        });

        contentList.listContent.forEach((content) =>
          this.selection.add(content.id)
        );

        if (this.allContent.length > 0) {
          this.allContent = this.getOrderedContent(
            this.allContent,
            this.selection
          );
        }
      }
    });

    this.contents$.subscribe((contents) => {
      if (contents.length > 0) {
        console.log(contents);

        this.allContent = contents;

        this.allContent = this.getOrderedContent(
          this.allContent,
          this.selection
        );
      }
    });
  }

  getOrderedContent(contentList: Content[], selection: Set<string>): Content[] {
    const selectedContent = contentList.filter((content) =>
      selection.has(content.id)
    );
    const unselectedContent = contentList.filter(
      (content) => !selection.has(content.id)
    );

    return [...selectedContent, ...unselectedContent];
  }

  onContentSelect(contentId: string) {
    if (this.selection.has(contentId)) {
      this.selection.delete(contentId);
    } else {
      this.selection.add(contentId);
    }

    this.allContent = this.getOrderedContent(this.allContent, this.selection);
  }

  isAllSelected(): boolean {
    return this.selection.size === this.allContent.length;
  }

  isIndeterminate(): boolean {
    return this.selection.size > 0 && !this.isAllSelected();
  }

  toggleSelectAll(event: MatCheckboxChange) {
    const isChecked = event.checked;
    if (isChecked) {
      this.allContent.forEach((content) => this.selection.add(content.id));
    } else {
      this.selection.clear();
    }
    this.allContent = this.getOrderedContent(this.allContent, this.selection);
  }

  onSubmit() {
    if (this.contentListForm.valid) {
      const {
        listName,
        listDescription,
        isActive,
        isFeatured,
        contentListIconName,
      } = this.contentListForm.value;

      const contentListData = {
        id: this.data.id,
        listName,
        listDescription,
        listContentIds: Array.from(this.selection),
        isActive,
        isFeatured,
        contentListIconName, // New field added
      };

      this.store.dispatch(
        new UpdateContentListAction(this.data.id, contentListData)
      );
      this.dialogRef.close();
    }
  }
}

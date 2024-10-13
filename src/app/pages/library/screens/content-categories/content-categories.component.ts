import { Component, inject, OnInit } from '@angular/core';
import { Store } from '@ngxs/store';
import { Observable } from 'rxjs';
import { AppState } from '../../../../state/app.store';
import {
  DeleteContentCategoryAction,
  GetContentCategoriesAction,
  ToggleContentCategoryStatusAction,
} from '../../../../state/app.actions';
import { ContentCategory } from '../../../../models/app.model';
import { MatBottomSheet } from '@angular/material/bottom-sheet';
import { MatDialog } from '@angular/material/dialog';
import { AddNewContentCategoryComponent } from './components/add-new-content-category/add-new-content-category.component';
import { EditContentCategoryComponent } from './components/edit-content-category/edit-content-category.component';
import { DeleteContentCategoryComponent } from './components/delete-content-category/delete-content-category.component';

@Component({
  selector: 'app-content-categories',
  templateUrl: './content-categories.component.html',
  styleUrl: './content-categories.component.scss',
})
export class ContentCategoriesComponent implements OnInit {
  contentCategories$: Observable<ContentCategory[]> = inject(Store).select(
    AppState.contentCategories
  );
  tableColumns: String[] = ['id', 'contentTypeName', 'enable', 'actions'];

  categories: ContentCategory[];

  constructor(
    private store: Store,
    private sheet: MatBottomSheet,
    private dialog: MatDialog
  ) {}
  ngOnInit(): void {
    this.store.dispatch(new GetContentCategoriesAction());
    this.contentCategories$.subscribe((data) => {
      if (data.length > 0) {
        this.categories = data;
      }
    });
  }

  onToggleClicked(id: string) {
    this.store.dispatch(new ToggleContentCategoryStatusAction(id));
  }

  openAddBottomSheet(): void {
    this.sheet.open(AddNewContentCategoryComponent);
  }
  openEditBottomSheet(type: ContentCategory): void {
    const dialogRef = this.dialog.open(EditContentCategoryComponent, {
      width: '400px',
      data: type,
    });

    dialogRef.afterClosed().subscribe((result) => {
      // You can handle any post-dialog actions here
    });
  }
  openDeleteDialog(contentType: ContentCategory): void {
    const dialogRef = this.dialog.open(DeleteContentCategoryComponent, {
      width: '400px',
      data: { contentType: contentType }, // Pass the name for confirmation
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result === true) {
        this.store.dispatch(new DeleteContentCategoryAction(contentType.id));
      }
    });
  }
}

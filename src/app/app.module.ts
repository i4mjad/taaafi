import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { AngularFireModule } from '@angular/fire/compat';
import { AngularFireAuthModule } from '@angular/fire/compat/auth';
import { AngularFirestoreModule } from '@angular/fire/compat/firestore';
import { environment } from '../environments/environment';
import { HomeComponent } from './pages/home/home.component';
import { DashboardComponent } from './pages/dashboard/dashboard.component';

import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';
import { MaterialModule } from './shared/material/material.module';
import { TranslateLoader, TranslateModule } from '@ngx-translate/core';
import { HttpClient, HttpClientModule } from '@angular/common/http';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';
import { NotFoundComponent } from './pages/errors-pages/not-found/not-found.component';
import { UnauthorizedAccessComponent } from './pages/errors-pages/unauthorized-access/unauthorized-access.component';
import { ForbiddenAccessComponent } from './pages/errors-pages/forbidden-access/forbidden-access.component';
import { LibraryComponent } from './pages/library/library.component';
import { VaultComponent } from './pages/vault/vault.component';
import { FellowshipsComponent } from './pages/fellowships/fellowships.component';
import { UsersManagementComponent } from './pages/users-management/users-management.component';
import { HlmButtonDirective } from '@spartan-ng/ui-button-helm';
import { SpartanCompnentsModule } from './shared/components/component.module';
import { NgxsModule } from '@ngxs/store';
import { AppState } from './state/app.store';
import { ContentTypesComponent } from './pages/library/screens/content-types/content-types.component';
import { AddNewContentTypeComponent } from './pages/library/screens/content-types/componenets/add-new-content-type/add-new-content-type.component';
import { EditContentTypeComponent } from './pages/library/screens/content-types/componenets/edit-content-type/edit-content-type.component';
import { DeleteContentTypeComponent } from './pages/library/screens/content-types/componenets/delete-content-type/delete-content-type.component';
import { AddNewContentCategoryComponent } from './pages/library/screens/content-categories/components/add-new-content-category/add-new-content-category.component';
import { DeleteContentCategoryComponent } from './pages/library/screens/content-categories/components/delete-content-category/delete-content-category.component';
import { EditContentCategoryComponent } from './pages/library/screens/content-categories/components/edit-content-category/edit-content-category.component';
import { ContentCategoriesComponent } from './pages/library/screens/content-categories/content-categories.component';
import { ContentOwnersComponent } from './pages/library/screens/content-owners/content-owners.component';
import { AddContentOwnerComponent } from './pages/library/screens/content-owners/components/add-content-owner/add-content-owner.component';
import { EditContentOwnerComponent } from './pages/library/screens/content-owners/components/edit-content-owner/edit-content-owner.component';
import { DeleteContentOwnerComponent } from './pages/library/screens/content-owners/components/delete-content-owner/delete-content-owner.component';
import { ContentComponent } from './pages/library/screens/content/content.component';
import { AddNewContentComponent } from './pages/library/screens/content/components/add-new-content/add-new-content.component';
import { EditContentComponent } from './pages/library/screens/content/components/edit-content/edit-content.component';
import { DeleteContentComponent } from './pages/library/screens/content/components/delete-content/delete-content.component';

import { ContentListsComponent } from './pages/library/screens/content-lists/content-lists.component';
import { AddNewContentListComponent } from './pages/library/screens/content-lists/components/add-new-content-list/add-new-content-list.component';
import { DeleteContentListComponent } from './pages/library/screens/content-lists/components/delete-content-list/delete-content-list.component';
import { EditContentListComponent } from './pages/library/screens/content-lists/components/edit-content-list/edit-content-list.component';

@NgModule({
  declarations: [
    AppComponent,
    HomeComponent,
    DashboardComponent,
    NotFoundComponent,
    UnauthorizedAccessComponent,
    ForbiddenAccessComponent,
    LibraryComponent,
    VaultComponent,
    FellowshipsComponent,
    UsersManagementComponent,
    ContentTypesComponent,
    AddNewContentTypeComponent,
    EditContentTypeComponent,
    DeleteContentTypeComponent,
    ContentCategoriesComponent,
    AddNewContentCategoryComponent,
    EditContentCategoryComponent,
    DeleteContentCategoryComponent,
    ContentOwnersComponent,
    AddContentOwnerComponent,
    EditContentOwnerComponent,
    DeleteContentOwnerComponent,
    ContentComponent,
    AddNewContentComponent,
    EditContentComponent,
    DeleteContentComponent,
    ContentListsComponent,
    AddNewContentListComponent,
    DeleteContentListComponent,
    EditContentListComponent,
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    HttpClientModule,
    NgxsModule.forRoot([AppState]),

    AngularFireModule.initializeApp(environment.firebase),
    AngularFireAuthModule, // Authentication module
    AngularFirestoreModule, // Firestore module
    MaterialModule,
    SpartanCompnentsModule,
    TranslateModule.forRoot({
      loader: {
        provide: TranslateLoader,
        useFactory: HttpLoaderFactory,
        deps: [HttpClient],
      },
    }),
  ],
  providers: [provideAnimationsAsync(), HttpClient],
  bootstrap: [AppComponent],
})
export class AppModule {}

export function HttpLoaderFactory(http: HttpClient) {
  return new TranslateHttpLoader(http, './assets/i18n/', '.json');
}

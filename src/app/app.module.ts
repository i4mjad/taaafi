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

import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { AuthGuard } from '@angular/fire/auth-guard';
import { HomeComponent } from './pages/home/home.component';
import { canActivateAuth } from './guards/auth.guard';
import { NotFoundComponent } from './pages/errors-pages/not-found/not-found.component';
import { ForbiddenAccessComponent } from './pages/errors-pages/forbidden-access/forbidden-access.component';
import { UnauthorizedAccessComponent } from './pages/errors-pages/unauthorized-access/unauthorized-access.component';
import { LibraryComponent } from './pages/library/library.component';
import { VaultComponent } from './pages/vault/vault.component';
import { FellowshipsComponent } from './pages/fellowships/fellowships.component';
import { UsersManagementComponent } from './pages/users-management/users-management.component';
import { ContentTypesComponent } from './pages/library/screens/content-types/content-types.component';
import { ContentCategoriesComponent } from './pages/library/screens/content-categories/content-categories.component';
import { ContentOwnersComponent } from './pages/library/screens/content-owners/content-owners.component';
import { ContentComponent } from './pages/library/screens/content/content.component';
import { ContentListsComponent } from './pages/library/screens/content-lists/content-lists.component';

const routes: Routes = [
  { path: '', component: HomeComponent },
  {
    path: 'dashboard',
    component: DashboardComponent,
    canActivate: [canActivateAuth],
  },
  // Main pages
  {
    path: 'library',
    component: LibraryComponent,
    canActivate: [canActivateAuth],
  },
  {
    path: 'library/content',
    component: ContentComponent,
    canActivate: [canActivateAuth],
  },
  {
    path: 'library/content-types',
    component: ContentTypesComponent,
    canActivate: [canActivateAuth],
  },
  {
    path: 'library/content-categories',
    component: ContentCategoriesComponent,
    canActivate: [canActivateAuth],
  },
  {
    path: 'library/content-owners',
    component: ContentOwnersComponent,
    canActivate: [canActivateAuth],
  },
  {
    path: 'library/content-lists',
    component: ContentListsComponent,
    canActivate: [canActivateAuth],
  },
  { path: 'vault', component: VaultComponent, canActivate: [canActivateAuth] },
  {
    path: 'fellowships',
    component: FellowshipsComponent,
    canActivate: [canActivateAuth],
  },
  {
    path: 'users-management',
    component: UsersManagementComponent,
    canActivate: [canActivateAuth],
  },

  // Error pages
  { path: 'not-found', component: NotFoundComponent },
  { path: 'forbidden-access', component: ForbiddenAccessComponent },
  { path: 'unauthorized-access', component: UnauthorizedAccessComponent },
  { path: 'not-found', component: NotFoundComponent },
  { path: '**', redirectTo: '/not-found' },
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule],
})
export class AppRoutingModule {}

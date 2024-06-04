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

const routes: Routes = [
  { path: '', component: HomeComponent },
  {
    path: 'dashboard',
    component: DashboardComponent,
    canActivate: [canActivateAuth],
  },
  { path: 'not-found', component: NotFoundComponent },
  { path: 'forbidden-access', component: ForbiddenAccessComponent },
  { path: 'unauthorized-access', component: UnauthorizedAccessComponent },
  { path: 'not-found', component: NotFoundComponent },
  { path: 'library', component: LibraryComponent },
  { path: 'vault', component: VaultComponent },
  { path: 'fellowships', component: FellowshipsComponent },
  { path: 'users-management', component: UsersManagementComponent },
  { path: '**', redirectTo: '/not-found' },
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule],
})
export class AppRoutingModule {}

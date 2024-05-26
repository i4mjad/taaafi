import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { AuthGuard } from '@angular/fire/auth-guard';
import { HomeComponent } from './pages/home/home.component';
import { canActivateAuth } from './guards/auth.guard';
import { NotFoundComponent } from './pages/errors-pages/not-found/not-found.component';
import { ForbiddenAccessComponent } from './pages/errors-pages/forbidden-access/forbidden-access.component';
import { UnauthorizedAccessComponent } from './pages/errors-pages/unauthorized-access/unauthorized-access.component';

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
  { path: '**', redirectTo: '/404' },
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule],
})
export class AppRoutingModule {}

import { NgModule } from '@angular/core';
import { ButtonModule } from 'primeng/button';
import { MenubarModule } from 'primeng/menubar';
import { AvatarModule } from 'primeng/avatar';
import { CardModule } from 'primeng/card';

const components = [MenubarModule, ButtonModule, AvatarModule, CardModule];
@NgModule({
  imports: components,
  exports: components,
})
export class PrimengModule {}

import { NgModule } from '@angular/core';
import { ButtonModule } from 'primeng/button';
const components = [ButtonModule];
@NgModule({
  imports: components,
  exports: components
})
export class PrimengModule { }

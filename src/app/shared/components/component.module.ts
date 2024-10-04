import { NgModule } from "@angular/core";
import { HlmButtonDirective } from "@spartan-ng/ui-button-helm";


const components = [
    HlmButtonDirective,
]

@NgModule({
    imports: components,
    exports: components,
})
export class SpartanCompnentsModule {}

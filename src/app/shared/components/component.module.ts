import { NgModule } from "@angular/core";
import { provideIcons } from "@ng-icons/core";
import { HlmButtonDirective } from "@spartan-ng/ui-button-helm";
import { HlmCardContentDirective, HlmCardDescriptionDirective, HlmCardDirective, HlmCardFooterDirective, HlmCardHeaderDirective, HlmCardTitleDirective } from "@spartan-ng/ui-card-helm";
import { HlmIconComponent } from "@spartan-ng/ui-icon-helm";
import { lucideChevronRight, lucideUsers } from '@ng-icons/lucide';



const components = [
    HlmButtonDirective,
    HlmCardContentDirective,
    HlmCardDescriptionDirective,
    HlmCardDirective,
    HlmCardFooterDirective,
    HlmCardHeaderDirective,
    HlmCardTitleDirective,
    HlmIconComponent,

]

@NgModule({
    imports: components,
    providers:[
        provideIcons({ lucideChevronRight,lucideUsers })
    ],
    exports: components,
})
export class SpartanCompnentsModule {}

import { DOCUMENT } from '@angular/common';
import { Component, Inject } from '@angular/core';

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrl: './home.component.scss',
})
export class HomeComponent {
  constructor(@Inject(DOCUMENT) private document: Document) {}

  goToAppUrl(): void {
    this.document.location.href = 'https://ta3afi.app';
  }
}

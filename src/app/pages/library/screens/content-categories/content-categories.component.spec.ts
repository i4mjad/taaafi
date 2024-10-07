import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ContentCategoriesComponent } from './content-categories.component';

describe('ContentCategoriesComponent', () => {
  let component: ContentCategoriesComponent;
  let fixture: ComponentFixture<ContentCategoriesComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ContentCategoriesComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(ContentCategoriesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

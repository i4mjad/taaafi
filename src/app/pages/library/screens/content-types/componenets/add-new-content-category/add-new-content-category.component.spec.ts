import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AddNewContentCategoryComponent } from './add-new-content-category.component';

describe('AddNewContentCategoryComponent', () => {
  let component: AddNewContentCategoryComponent;
  let fixture: ComponentFixture<AddNewContentCategoryComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [AddNewContentCategoryComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(AddNewContentCategoryComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

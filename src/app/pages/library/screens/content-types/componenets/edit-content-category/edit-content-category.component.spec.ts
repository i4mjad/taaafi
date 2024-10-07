import { ComponentFixture, TestBed } from '@angular/core/testing';

import { EditContentCategoryComponent } from './edit-content-category.component';

describe('EditContentCategoryComponent', () => {
  let component: EditContentCategoryComponent;
  let fixture: ComponentFixture<EditContentCategoryComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [EditContentCategoryComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(EditContentCategoryComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

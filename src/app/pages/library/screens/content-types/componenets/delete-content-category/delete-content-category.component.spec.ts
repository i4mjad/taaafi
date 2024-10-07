import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DeleteContentCategoryComponent } from './delete-content-category.component';

describe('DeleteContentCategoryComponent', () => {
  let component: DeleteContentCategoryComponent;
  let fixture: ComponentFixture<DeleteContentCategoryComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [DeleteContentCategoryComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(DeleteContentCategoryComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

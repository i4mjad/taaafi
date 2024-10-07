import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AddNewContentTypeComponent } from './add-new-content-type.component';

describe('AddNewContentTypeComponent', () => {
  let component: AddNewContentTypeComponent;
  let fixture: ComponentFixture<AddNewContentTypeComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [AddNewContentTypeComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(AddNewContentTypeComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

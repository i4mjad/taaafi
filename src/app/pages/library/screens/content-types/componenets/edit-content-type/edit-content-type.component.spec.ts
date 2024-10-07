import { ComponentFixture, TestBed } from '@angular/core/testing';

import { EditContentTypeComponent } from './edit-content-type.component';

describe('EditContentTypeComponent', () => {
  let component: EditContentTypeComponent;
  let fixture: ComponentFixture<EditContentTypeComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [EditContentTypeComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(EditContentTypeComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

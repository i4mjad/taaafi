import { ComponentFixture, TestBed } from '@angular/core/testing';

import { EditContentOwnerComponent } from './edit-content-owner.component';

describe('EditContentOwnerComponent', () => {
  let component: EditContentOwnerComponent;
  let fixture: ComponentFixture<EditContentOwnerComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [EditContentOwnerComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(EditContentOwnerComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

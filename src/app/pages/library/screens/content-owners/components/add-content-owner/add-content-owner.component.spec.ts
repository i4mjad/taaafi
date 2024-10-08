import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AddContentOwnerComponent } from './add-content-owner.component';

describe('AddContentOwnerComponent', () => {
  let component: AddContentOwnerComponent;
  let fixture: ComponentFixture<AddContentOwnerComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [AddContentOwnerComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(AddContentOwnerComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AddNewContentComponent } from './add-new-content.component';

describe('AddNewContentComponent', () => {
  let component: AddNewContentComponent;
  let fixture: ComponentFixture<AddNewContentComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [AddNewContentComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(AddNewContentComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

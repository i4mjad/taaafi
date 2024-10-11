import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AddNewContentListComponent } from './add-new-content-list.component';

describe('AddNewContentListComponent', () => {
  let component: AddNewContentListComponent;
  let fixture: ComponentFixture<AddNewContentListComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [AddNewContentListComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(AddNewContentListComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

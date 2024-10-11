import { ComponentFixture, TestBed } from '@angular/core/testing';

import { EditContentListComponent } from './edit-content-list.component';

describe('EditContentListComponent', () => {
  let component: EditContentListComponent;
  let fixture: ComponentFixture<EditContentListComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [EditContentListComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(EditContentListComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

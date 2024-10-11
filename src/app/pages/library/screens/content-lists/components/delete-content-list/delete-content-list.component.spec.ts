import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DeleteContentListComponent } from './delete-content-list.component';

describe('DeleteContentListComponent', () => {
  let component: DeleteContentListComponent;
  let fixture: ComponentFixture<DeleteContentListComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [DeleteContentListComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(DeleteContentListComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

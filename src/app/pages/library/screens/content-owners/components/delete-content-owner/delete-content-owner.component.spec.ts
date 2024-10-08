import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DeleteContentOwnerComponent } from './delete-content-owner.component';

describe('DeleteContentOwnerComponent', () => {
  let component: DeleteContentOwnerComponent;
  let fixture: ComponentFixture<DeleteContentOwnerComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [DeleteContentOwnerComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(DeleteContentOwnerComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

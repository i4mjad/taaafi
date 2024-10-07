import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DeleteContentTypeComponent } from './delete-content-type.component';

describe('DeleteContentTypeComponent', () => {
  let component: DeleteContentTypeComponent;
  let fixture: ComponentFixture<DeleteContentTypeComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [DeleteContentTypeComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(DeleteContentTypeComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

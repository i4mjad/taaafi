import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DeleteContentComponent } from './delete-content.component';

describe('DeleteContentComponent', () => {
  let component: DeleteContentComponent;
  let fixture: ComponentFixture<DeleteContentComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [DeleteContentComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(DeleteContentComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

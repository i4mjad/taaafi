import { ComponentFixture, TestBed } from '@angular/core/testing';

import { UpdateActivityTaskComponent } from './update-activity-task.component';

describe('UpdateActivityTaskComponent', () => {
  let component: UpdateActivityTaskComponent;
  let fixture: ComponentFixture<UpdateActivityTaskComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [UpdateActivityTaskComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(UpdateActivityTaskComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

import { ComponentFixture, TestBed } from '@angular/core/testing';

import { UpdateActivityTasksComponent } from './update-activity-tasks.component';

describe('UpdateActivityTasksComponent', () => {
  let component: UpdateActivityTasksComponent;
  let fixture: ComponentFixture<UpdateActivityTasksComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [UpdateActivityTasksComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(UpdateActivityTasksComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

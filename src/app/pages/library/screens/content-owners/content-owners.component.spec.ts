import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ContentOwnersComponent } from './content-owners.component';

describe('ContentOwnersComponent', () => {
  let component: ContentOwnersComponent;
  let fixture: ComponentFixture<ContentOwnersComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ContentOwnersComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ContentOwnersComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

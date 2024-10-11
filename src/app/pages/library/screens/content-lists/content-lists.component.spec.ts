import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ContentListsComponent } from './content-lists.component';

describe('ContentListsComponent', () => {
  let component: ContentListsComponent;
  let fixture: ComponentFixture<ContentListsComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ContentListsComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(ContentListsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

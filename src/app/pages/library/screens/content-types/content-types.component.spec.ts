import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ContentTypesComponent } from './content-types.component';

describe('ContentTypesComponent', () => {
  let component: ContentTypesComponent;
  let fixture: ComponentFixture<ContentTypesComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ContentTypesComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(ContentTypesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

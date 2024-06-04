import { ComponentFixture, TestBed } from '@angular/core/testing';

import { FellowshipsComponent } from './fellowships.component';

describe('FellowshipsComponent', () => {
  let component: FellowshipsComponent;
  let fixture: ComponentFixture<FellowshipsComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [FellowshipsComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(FellowshipsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

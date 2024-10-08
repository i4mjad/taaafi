import { TestBed } from '@angular/core/testing';

import { ContentOwnerService } from './content-owner.service';

describe('ContentOwnerService', () => {
  let service: ContentOwnerService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(ContentOwnerService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});

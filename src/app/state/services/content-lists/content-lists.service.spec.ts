import { TestBed } from '@angular/core/testing';

import { ContentListsService } from './content-lists.service';

describe('ContentListsService', () => {
  let service: ContentListsService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(ContentListsService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});

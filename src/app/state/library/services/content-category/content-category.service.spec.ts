import { TestBed } from '@angular/core/testing';

import { ContentCategoryService } from './content-category.service';

describe('ContentCategoryService', () => {
  let service: ContentCategoryService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(ContentCategoryService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});

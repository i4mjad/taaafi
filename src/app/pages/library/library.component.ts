import { Component, inject, OnInit } from '@angular/core';
import { AppState } from '../../state/app.store';
import { dispatch, Select, Store } from '@ngxs/store';
import { Observable } from 'rxjs';
import { GetContentTypesAction } from '../../state/app.actions';

@Component({
  selector: 'app-library',
  templateUrl: './library.component.html',
  styleUrl: './library.component.scss'
})
export class LibraryComponent implements OnInit {


  contentTypes$: Observable<string[]> = inject(Store).select(AppState.contentTypes);

  constructor(private store:Store) {}
  ngOnInit(): void {
    this.store.dispatch(new GetContentTypesAction());
    this.contentTypes$.subscribe((data)=>{
      if(data.length > 0){


      }
    });
  }

}

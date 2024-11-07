import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';

@Component({
  selector: 'app-activity',
  templateUrl: './activity.component.html',
  styleUrl: './activity.component.scss',
})
export class ActivityComponent implements OnInit {
  activityId: string;

  constructor(private route: ActivatedRoute, private router: Router) {}
  ngOnInit(): void {
    if (this.route.snapshot.paramMap.get('id')) {
      this.activityId = this.route.snapshot.paramMap.get('id')!;
    }
  }
}

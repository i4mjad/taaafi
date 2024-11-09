import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { TaskFrequency } from '../../../../../../models/vault.model';

@Component({
  selector: 'app-create-activity',
  templateUrl: './create-activity.component.html',
  styleUrls: ['./create-activity.component.scss'],
})
export class CreateActivityComponent implements OnInit {
  activityForm: FormGroup;
  taskFrequencies = Object.values(TaskFrequency);

  constructor(private fb: FormBuilder) {}

  ngOnInit(): void {
    this.activityForm = this.fb.group({
      activityName: ['', Validators.required],
      activityDifficulty: ['', Validators.required],
      activityDescription: ['', Validators.required],
      activityTasks: this.fb.array([]),
    });
  }

  get activityTasks(): FormArray {
    return this.activityForm.get('activityTasks') as FormArray;
  }

  addTask(): void {
    const taskGroup = this.fb.group({
      taskName: ['', Validators.required],
      taskDescription: ['', Validators.required],
      taskFrequency: ['', Validators.required],
    });
    this.activityTasks.push(taskGroup);
  }

  removeTask(index: number): void {
    this.activityTasks.removeAt(index);
  }

  resetForm(): void {
    this.activityForm.reset();
    while (this.activityTasks.length) {
      this.activityTasks.removeAt(0);
    }
  }

  onSubmit(): void {
    if (this.activityForm.valid) {
      console.log(this.activityForm.value);
      // Handle form submission logic here
    }
  }
}

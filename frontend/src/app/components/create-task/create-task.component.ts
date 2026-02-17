import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { QueueService } from '../../services/queue.service';

@Component({
  selector: 'app-create-task',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './create-task.component.html',
  styleUrls: ['./create-task.component.scss']
})
export class CreateTaskComponent implements OnInit {
  taskForm!: FormGroup;
  loading: boolean = false;

  constructor(
    private fb: FormBuilder,
    private queueService: QueueService
  ) { }

  ngOnInit(): void {
    // Initialize the form with a default argument row
    this.taskForm = this.fb.group({
      className: [''],
      methodName: [''],
      routineName: [''],
      priority: [1, Validators.required],
      args: this.fb.array([this.createArgGroup()])
    });

    this.setupConditionalLogic();
  }

  // Helper to create a new key-value pair group for the Arguments list
  createArgGroup(): FormGroup {
    return this.fb.group({
      key: [''],
      value: ['']
    });
  }

  // Getter for easy access to the args FormArray in HTML
  get args(): FormArray {
    return this.taskForm.get('args') as FormArray;
  }

  addRow(): void {
    this.args.push(this.createArgGroup());
  }

  removeRow(index: number): void {
    if (this.args.length > 1) {
      this.args.removeAt(index);
    }
  }

  /**
   * Logical restriction:
   * If Class Name is filled, Routine is disabled.
   * If Routine Name is filled, Class & Method are disabled.
   */
  private setupConditionalLogic(): void {
    // Watch Class Name
    this.taskForm.get('className')?.valueChanges.subscribe(val => {
      if (val && val.trim() !== '') {
        this.taskForm.get('routineName')?.disable({ emitEvent: false });
      } else {
        this.taskForm.get('routineName')?.enable({ emitEvent: false });
      }
    });

    // Watch Routine Name
    this.taskForm.get('routineName')?.valueChanges.subscribe(val => {
      if (val && val.trim() !== '') {
        this.taskForm.get('className')?.disable({ emitEvent: false });
        this.taskForm.get('methodName')?.disable({ emitEvent: false });
      } else {
        this.taskForm.get('className')?.enable({ emitEvent: false });
        this.taskForm.get('methodName')?.enable({ emitEvent: false });
      }
    });
  }

  saveToQueue(): void {
    if (this.taskForm.invalid) return;

    const rawData = this.taskForm.getRawValue();

    // Custom Validation: Class needs Method
    if (rawData.className && !rawData.methodName) {
      alert("Method Name is mandatory when Class Name is provided.");
      return;
    }

    // Custom Validation: Must have either Class or Routine
    if (!rawData.className && !rawData.routineName) {
      alert("Please provide either a Class/Method or a Routine.");
      return;
    }

    this.loading = true;

    // Transform FormArray [{key: 'a', value: '1'}] to Object {a: '1'}
    const argsObj: Record<string, any> = {};
    rawData.args.forEach((arg: any) => {
      if (arg.key && arg.key.trim() !== '') {
        argsObj[arg.key] = arg.value;
      }
    });

    // Construct the final JSON payload for IRIS
    const payload = {
      QueueInfo: {
        ClassName: rawData.className,
        MethodName: rawData.methodName,
        RoutineName: rawData.routineName,
        Args: argsObj
      },
      Priority: parseInt(rawData.priority, 10)
    };



    this.queueService.addToQueue(payload).subscribe({
      next: (response) => {
        this.loading = false;
        alert(response.message);
        this.resetForm();
      },
      error: (err: HttpErrorResponse) => {
        this.loading = false;
        alert("Error saving to queue: " + (err.error?.message || err.message));
      }
    });
  }

  resetForm(): void {
    this.taskForm.reset({ priority: 1 });
    // Clear the array and put back one empty row
    while (this.args.length !== 0) {
      this.args.removeAt(0);
    }
    this.addRow();
  }
}
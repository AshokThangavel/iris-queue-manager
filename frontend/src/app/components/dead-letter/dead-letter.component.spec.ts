import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DeadLetterComponent } from './dead-letter.component';

describe('DeadLetterComponent', () => {
  let component: DeadLetterComponent;
  let fixture: ComponentFixture<DeadLetterComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DeadLetterComponent]
    })
      .compileComponents();

    fixture = TestBed.createComponent(DeadLetterComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

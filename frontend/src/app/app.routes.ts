import { Routes } from '@angular/router';
import { QueueListComponent } from './components/queue-list/queue-list.component';
import { DeadLetterComponent } from './components/dead-letter/dead-letter.component';
import { HistoryComponent } from './components/history/history.component';
import { CreateTaskComponent } from './components/create-task/create-task.component';

export const routes: Routes = [
    { path: 'queue', component: QueueListComponent },
    { path: 'deadletter', component: DeadLetterComponent }, // Check this line!
    { path: 'history', component: HistoryComponent },
    { path: 'create', component: CreateTaskComponent },
    { path: '', redirectTo: '/queue', pathMatch: 'full' }
];
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common'; // Required for @for and @if
import { FormsModule } from '@angular/forms';
import { QueueService, QueueItem } from '../../services/queue.service';
import { HttpClient } from '@angular/common/http'; // 1. Add this import

@Component({
  selector: 'app-queue-list',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './queue-list.component.html',
  styleUrls: ['./queue-list.component.scss']
})
export class QueueListComponent implements OnInit {
  items: QueueItem[] = [];
  selectedIds: Set<number> = new Set();
  filteredItems: QueueItem[] = [];
  searchTerm: string = '';
  loading: boolean = false;
  isQueueRunning: boolean = false;
  queuePid: string = '';

  constructor(private queueService: QueueService, private http: HttpClient) { }

  ngOnInit(): void {
    this.loadQueue();
    this.checkQueueStatus();
  }

  loadQueue() {
    this.loading = true;
    this.queueService.getItems('active').subscribe({
      next: (data) => {
        this.items = data;
        this.applyFilter(); // Initial display
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading queue:', err);
        this.loading = false;
      }
    });
  }

  // FIX FOR ERROR: Property 'applyFilter' does not exist
  applyFilter() {
    const search = this.searchTerm.toLowerCase().trim();
    if (!search) {
      this.filteredItems = [...this.items];
    } else {
      this.filteredItems = this.items.filter(item =>
        item.id?.toString().includes(search) ||
        item.status?.toLowerCase().includes(search) ||
        item.executionInfo?.toLowerCase().includes(search)
      );
    }
  }
  toggleSelection(id: number) {
    if (this.selectedIds.has(id)) {
      this.selectedIds.delete(id);
    } else {
      this.selectedIds.add(id);
    }
  }

  toggleAll(event: any) {
    if (event.target.checked) {
      this.items.forEach(item => this.selectedIds.add(item.id));
    } else {
      this.selectedIds.clear();
    }
  }

  deleteSingle(id: number) {
    if (confirm('Are you sure you want to delete this item?')) {
      this.queueService.deleteItem(id).subscribe(() => this.loadQueue());
    }
  }

  // THIS IS THE MISSING METHOD
  deleteSelected() {
    if (confirm(`Delete ${this.selectedIds.size} selected items?`)) {
      const idsArray = Array.from(this.selectedIds);
      this.queueService.bulkDelete(idsArray).subscribe(() => {
        this.selectedIds.clear();
        this.loadQueue();
      });
    }
  }
  checkQueueStatus() {
    this.queueService.getQueueStatus().subscribe((res: any) => {
      // Assuming response returns { running: true, pid: '1234' }
      this.isQueueRunning = res.running;
      this.queuePid = res.pid;
    });
  }

  startQueue() {
    this.loading = true;
    this.queueService.startQueue().subscribe({
      next: (res: any) => {
        this.checkQueueStatus();
        this.loadQueue(); // Refresh list to see items start processing
      },
      complete: () => this.loading = false
    });
  }

  stopQueue() {
    const confirmed = confirm("Are you sure you want to stop the Queue process? Active tasks will pause until the queue is restarted.");
    if (confirmed) {
      this.loading = true;
      this.queueService.stopQueue().subscribe({
        next: () => {
          this.checkQueueStatus();
        },
        error: (err) => {
          console.error("Failed to stop queue", err);
          this.loading = false;
        },
        complete: () => this.loading = false
      });
    }
  }
}
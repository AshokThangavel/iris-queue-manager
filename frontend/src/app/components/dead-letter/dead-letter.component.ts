import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { QueueService, QueueItem, DeadLetterItem } from '../../services/queue.service';

@Component({
  selector: 'app-dead-letter',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './dead-letter.component.html',
  styleUrls: ['./dead-letter.component.scss']
})
export class DeadLetterComponent implements OnInit {
  items: DeadLetterItem[] = [];
  filteredItems: DeadLetterItem[] = [];
  selectedIds: Set<number> = new Set();
  searchTerm: string = '';
  loading: boolean = false;

  constructor(private queueService: QueueService) { }

  ngOnInit(): void {
    this.loadDeadLetter();
  }

  loadDeadLetter() {
    this.loading = true;
    // Note: ensure this method exists in your queueService
    this.queueService.getdlqItems().subscribe({
      next: (data) => {
        this.items = data;
        this.applyFilter();
        this.loading = false;
      },
      error: (err) => {
        console.error('Error fetching DLQ:', err);
        this.loading = false;
      }
    });
  }

  // Fixes NG9: Property 'applyFilter' does not exist
  applyFilter() {
    if (!this.searchTerm.trim()) {
      this.filteredItems = [...this.items];
    } else {
      const search = this.searchTerm.toLowerCase();
      this.filteredItems = this.items.filter(item =>
        item.id?.toString().includes(search) ||
        item.executionInfo?.toLowerCase().includes(search) ||
        item.lastError?.toLowerCase().includes(search)
      );
    }
  }

  toggleSelection(id: number) {
    this.selectedIds.has(id) ? this.selectedIds.delete(id) : this.selectedIds.add(id);
  }

  toggleAll(event: any) {
    if (event.target.checked) {
      this.items.forEach(item => this.selectedIds.add(item.id));
    } else {
      this.selectedIds.clear();
    }
  }

  deleteSelected() {
    if (confirm(`Permanently delete ${this.selectedIds.size} failed tasks?`)) {
      const idsArray = Array.from(this.selectedIds);
      this.queueService.bulkdlqDelete(idsArray).subscribe(() => {
        this.selectedIds.clear();
        this.loadDeadLetter();
      });
    }
  }

  deleteSingle(id: number) {
    if (confirm('Delete this failed task?')) {
      this.queueService.deletedlqItem(id).subscribe(() => this.loadDeadLetter());
    }
  }

  retrySingle(id: number) {
    this.queueService.retryItem(id).subscribe({
      next: () => {
        // Success! Reload the list so the item disappears from DLQ
        this.loadDeadLetter();
        console.log(`Item #${id} sent back to queue.`);
      },
      error: (err) => alert('Failed to retry item: ' + err.message)
    });
  }
}
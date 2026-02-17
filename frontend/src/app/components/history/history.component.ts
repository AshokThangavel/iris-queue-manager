import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { QueueService, HistoryItem } from '../../services/queue.service';

@Component({
  selector: 'app-history',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './history.component.html',
  styleUrls: ['./history.component.scss']
})
export class HistoryComponent implements OnInit {
  items: HistoryItem[] = [];
  filteredItems: HistoryItem[] = [];
  selectedIds: Set<number> = new Set();
  searchTerm: string = '';
  loading: boolean = false;

  constructor(private queueService: QueueService) { }

  ngOnInit(): void {
    this.loadHistory();
  }

  loadHistory() {
    this.loading = true;
    this.queueService.gethistItems().subscribe({
      next: (data) => {
        this.items = data;
        this.applyFilter(); // Initial filter
        this.loading = false;
      },
      error: () => this.loading = false
    });
  }
  applyFilter() {
    console.log('Searching for:', this.searchTerm); // Check F12 to see if this fires

    if (!this.searchTerm.trim()) {
      this.filteredItems = [...this.items];
    } else {
      const search = this.searchTerm.toLowerCase();

      this.filteredItems = this.items.filter(item => {
        // Safely check each field, converting to string and handling nulls
        const idMatch = item.id?.toString().includes(search);
        const infoMatch = item.executionInfo?.toLowerCase().includes(search);
        const timeMatch = item.completedTime?.toLowerCase().includes(search);

        return idMatch || infoMatch || timeMatch;
      });
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
    if (confirm('Remove this entry from history?')) {
      this.queueService.deletehistItem(id).subscribe(() => this.loadHistory());
    }
  }

  deleteSelected() {
    if (confirm(`Remove ${this.selectedIds.size} entries from history?`)) {
      const idsArray = Array.from(this.selectedIds);
      this.queueService.bulkhistDelete(idsArray).subscribe(() => {
        this.selectedIds.clear();
        this.loadHistory();
      });
    }
  }
}
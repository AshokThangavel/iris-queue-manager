import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

// Models
export interface QueueItem { id: number; priority: number; status: string; nextRun: string; executionInfo: string; retry: string; error: string; }
export interface HistoryItem { id: number; completedTime: string; duration: number; executionInfo: string; }
export interface DeadLetterItem { id: number; lastError: string; executionInfo: string; failedAt: string; retryCount: number; }

@Injectable({ providedIn: 'root' })
export class QueueService {
  private apiUrl = 'http://localhost:52773/api/zqueue';

  constructor(private http: HttpClient) { }

  // THIS IS THE MISSING METHOD CAUSING YOUR ERROR


  gethistItems(): Observable<HistoryItem[]> {
    return this.http.get<HistoryItem[]>(`${this.apiUrl}/items/history`);
  }
  getItems(status: string): Observable<QueueItem[]> {
    return this.http.get<QueueItem[]>(`${this.apiUrl}/items/${status}`);
  }

  getdlqItems(): Observable<DeadLetterItem[]> {
    return this.http.get<DeadLetterItem[]>(`${this.apiUrl}/items/dlq`);
  }


  deleteItem(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/item/${id}`);
  }
  getQueueStatus(): Observable<any> {
    return this.http.get(`${this.apiUrl}/queue/status`);
  }
  startQueue(): Observable<any> {
    return this.http.post(`${this.apiUrl}/queue/start`, {});
  }
  stopQueue(): Observable<any> {
    return this.http.post(`${this.apiUrl}/queue/stop`, {});
  }
  deletehistItem(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/items/history/${id}`);
  }
  deletedlqItem(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/items/dlq/${id}`);
  }
  bulkDelete(ids: number[]): Observable<any> {
    return this.http.post(`${this.apiUrl}/bulk-delete`, { ids });
  }

  bulkhistDelete(ids: number[]): Observable<any> {
    return this.http.post(`${this.apiUrl}/items/history/bulk-delete`, { ids });
  }
  bulkdlqDelete(ids: number[]): Observable<any> {
    return this.http.post(`${this.apiUrl}/items/dlq/bulk-delete`, { ids });
  }

  retryItem(id: number): Observable<any> {
    // This sends a POST to your IRIS endpoint to move the item back to the queue
    return this.http.post(`${this.apiUrl}/items/dlq/${id}/retry`, {});
  }
  createItem(payload: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/item`, payload);
  }

  // In src/app/services/queue.service.ts
  addToQueue(taskData: any): Observable<any> {
    // This should match your IRIS REST endpoint
    return this.http.post(`${this.apiUrl}/item`, taskData);
  }
}
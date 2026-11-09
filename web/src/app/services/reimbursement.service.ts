import { HttpClient, HttpErrorResponse, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, catchError, throwError } from 'rxjs';
import { Reimbursement, ReimbursementStatus } from '../models/reimbursement.model';

export const API_BASE_URL = 'http://localhost:5000/api/reimbursements';

/** Error ya traducido a un mensaje legible, conservando el código HTTP. */
export class ApiRequestError extends Error {
  constructor(message: string, public readonly status: number) {
    super(message);
  }
}

@Injectable({ providedIn: 'root' })
export class ReimbursementService {
  private readonly http = inject(HttpClient);

  getAll(status?: ReimbursementStatus): Observable<Reimbursement[]> {
    let params = new HttpParams();
    if (status) params = params.set('status', status);
    return this.http
      .get<Reimbursement[]>(API_BASE_URL, { params })
      .pipe(catchError(this.toApiError));
  }

  approve(id: number): Observable<Reimbursement> {
    return this.http
      .patch<Reimbursement>(`${API_BASE_URL}/${id}/approve`, null)
      .pipe(catchError(this.toApiError));
  }

  reject(id: number, reason: string): Observable<Reimbursement> {
    return this.http
      .patch<Reimbursement>(`${API_BASE_URL}/${id}/reject`, { reason })
      .pipe(catchError(this.toApiError));
  }

  private toApiError(err: HttpErrorResponse): Observable<never> {
    let message: string;
    if (err.status === 0) {
      message = 'No se pudo conectar con la API. Verifique que esté encendida en el puerto 5000.';
    } else if (err.status >= 500) {
      message = 'El servidor tuvo un problema. Intente de nuevo.';
    } else {
      message = err.error?.message ?? `Error ${err.status}.`;
    }
    return throwError(() => new ApiRequestError(message, err.status));
  }
}

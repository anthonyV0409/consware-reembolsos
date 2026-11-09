import { CurrencyPipe, DatePipe } from '@angular/common';
import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Reimbursement, ReimbursementStatus } from '../../models/reimbursement.model';
import { ApiRequestError, ReimbursementService } from '../../services/reimbursement.service';

type Filter = ReimbursementStatus | 'All';

interface Notice {
  kind: 'ok' | 'error';
  text: string;
}

@Component({
  selector: 'app-approvals',
  imports: [FormsModule, CurrencyPipe, DatePipe],
  templateUrl: './approvals.component.html',
  styleUrl: './approvals.component.scss',
})
export class ApprovalsComponent implements OnInit {
  private readonly service = inject(ReimbursementService);

  readonly filters: { value: Filter; label: string }[] = [
    { value: 'Pending', label: 'Pendientes' },
    { value: 'Approved', label: 'Aprobadas' },
    { value: 'Rejected', label: 'Rechazadas' },
    { value: 'All', label: 'Todas' },
  ];

  readonly statusLabels: Record<ReimbursementStatus, string> = {
    Pending: 'Pendiente',
    Approved: 'Aprobada',
    Rejected: 'Rechazada',
  };

  readonly filter = signal<Filter>('Pending');
  readonly items = signal<Reimbursement[]>([]);
  readonly loading = signal(false);
  readonly loadError = signal<string | null>(null);
  readonly notice = signal<Notice | null>(null);
  readonly busyId = signal<number | null>(null);

  // Diálogo de rechazo
  readonly rejecting = signal<Reimbursement | null>(null);
  readonly reason = signal('');
  readonly reasonTouched = signal(false);
  readonly rejectError = signal<string | null>(null);
  readonly reasonValid = computed(() => this.reason().trim().length > 0);

  readonly pendingTotal = computed(() =>
    this.items()
      .filter((r) => r.status === 'Pending')
      .reduce((sum, r) => sum + r.amount, 0),
  );

  ngOnInit(): void {
    this.load();
  }

  setFilter(value: Filter): void {
    if (this.filter() === value) return;
    this.filter.set(value);
    this.notice.set(null);
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.loadError.set(null);
    const f = this.filter();
    this.service.getAll(f === 'All' ? undefined : f).subscribe({
      next: (data) => {
        this.items.set(data);
        this.loading.set(false);
      },
      error: (err: ApiRequestError) => {
        this.loadError.set(err.message);
        this.loading.set(false);
      },
    });
  }

  approve(item: Reimbursement): void {
    const ok = window.confirm(
      `¿Aprobar la solicitud #${item.id} de ${item.employeeName} por $${item.amount.toLocaleString('es-CO')}?`,
    );
    if (!ok) return;

    this.busyId.set(item.id);
    this.service.approve(item.id).subscribe({
      next: () => {
        this.busyId.set(null);
        this.notice.set({ kind: 'ok', text: `Solicitud #${item.id} aprobada.` });
        this.load();
      },
      error: (err: ApiRequestError) => {
        this.busyId.set(null);
        this.handleDecisionError(err);
      },
    });
  }

  openReject(item: Reimbursement): void {
    this.rejecting.set(item);
    this.reason.set('');
    this.reasonTouched.set(false);
    this.rejectError.set(null);
  }

  closeReject(): void {
    if (this.busyId() !== null) return;
    this.rejecting.set(null);
  }

  confirmReject(): void {
    const item = this.rejecting();
    if (!item) return;
    this.reasonTouched.set(true);
    if (!this.reasonValid()) return;

    this.busyId.set(item.id);
    this.rejectError.set(null);
    this.service.reject(item.id, this.reason().trim()).subscribe({
      next: () => {
        this.busyId.set(null);
        this.rejecting.set(null);
        this.notice.set({ kind: 'ok', text: `Solicitud #${item.id} rechazada.` });
        this.load();
      },
      error: (err: ApiRequestError) => {
        this.busyId.set(null);
        if (err.status === 400) {
          // Motivo inválido: el diálogo sigue abierto para corregir.
          this.rejectError.set(err.message);
          return;
        }
        this.rejecting.set(null);
        this.handleDecisionError(err);
      },
    });
  }

  private handleDecisionError(err: ApiRequestError): void {
    if (err.status === 409) {
      this.notice.set({
        kind: 'error',
        text: `${err.message} La tabla se actualizó con el estado actual.`,
      });
      this.load();
      return;
    }
    if (err.status === 404) {
      this.notice.set({ kind: 'error', text: err.message });
      this.load();
      return;
    }
    this.notice.set({ kind: 'error', text: err.message });
  }
}

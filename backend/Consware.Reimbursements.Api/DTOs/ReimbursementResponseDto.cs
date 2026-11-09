using Consware.Reimbursements.Api.Models;

namespace Consware.Reimbursements.Api.DTOs;

public record ReimbursementResponseDto(
    int Id,
    string EmployeeName,
    decimal Amount,
    string Category,
    string Description,
    string Status,
    string? RejectionReason,
    DateTime CreatedAtUtc,
    DateTime? DecidedAtUtc)
{
    // SQL Server (datetime2) no guarda el "Kind"; se marca como UTC para que el JSON lleve la "Z".
    public static ReimbursementResponseDto FromEntity(ReimbursementRequest e) => new(
        e.Id,
        e.EmployeeName,
        e.Amount,
        e.Category,
        e.Description,
        e.Status.ToString(),
        e.RejectionReason,
        DateTime.SpecifyKind(e.CreatedAtUtc, DateTimeKind.Utc),
        e.DecidedAtUtc is null ? null : DateTime.SpecifyKind(e.DecidedAtUtc.Value, DateTimeKind.Utc));
}

namespace Consware.Reimbursements.Api.DTOs;

public record CreateReimbursementDto(
    string? EmployeeName,
    decimal Amount,
    string? Category,
    string? Description);

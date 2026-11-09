using Consware.Reimbursements.Api.DTOs;

namespace Consware.Reimbursements.Api.Services;

public interface IReimbursementService
{
    Task<ReimbursementResponseDto> CreateAsync(CreateReimbursementDto dto);
    Task<List<ReimbursementResponseDto>> GetAllAsync(string? status, string? employeeName);
    Task<ReimbursementResponseDto> GetByIdAsync(int id);
    Task<ReimbursementResponseDto> ApproveAsync(int id);
    Task<ReimbursementResponseDto> RejectAsync(int id, string? reason);
}

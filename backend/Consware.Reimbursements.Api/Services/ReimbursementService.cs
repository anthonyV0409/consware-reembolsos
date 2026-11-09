using Consware.Reimbursements.Api.Data;
using Consware.Reimbursements.Api.DTOs;
using Consware.Reimbursements.Api.Exceptions;
using Consware.Reimbursements.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace Consware.Reimbursements.Api.Services;

public class ReimbursementService(AppDbContext db) : IReimbursementService
{
    /// <summary>Montos menores o iguales a este valor (COP) se aprueban automáticamente.</summary>
    public const decimal AutoApprovalLimit = 500_000m;

    /// <summary>Máximo que cabe en DECIMAL(18,2).</summary>
    private const decimal MaxAmount = 9_999_999_999_999_999.99m;

    public async Task<ReimbursementResponseDto> CreateAsync(CreateReimbursementDto dto)
    {
        var employeeName = Require(dto.EmployeeName, "El nombre del empleado es obligatorio.", 100, "El nombre del empleado");
        var category = Require(dto.Category, "La categoría es obligatoria.", 60, "La categoría");
        var description = Require(dto.Description, "La descripción es obligatoria.", 500, "La descripción");

        if (dto.Amount <= 0)
            throw new ValidationException("El monto debe ser mayor a cero.");
        if (decimal.Round(dto.Amount, 2) != dto.Amount)
            throw new ValidationException("El monto admite máximo dos decimales.");
        if (dto.Amount > MaxAmount)
            throw new ValidationException("El monto excede el máximo permitido.");

        var now = DateTime.UtcNow;
        var autoApproved = dto.Amount <= AutoApprovalLimit;

        var entity = new ReimbursementRequest
        {
            EmployeeName = employeeName,
            Amount = dto.Amount,
            Category = category,
            Description = description,
            Status = autoApproved ? ReimbursementStatus.Approved : ReimbursementStatus.Pending,
            CreatedAtUtc = now,
            DecidedAtUtc = autoApproved ? now : null
        };

        db.ReimbursementRequests.Add(entity);
        await db.SaveChangesAsync();

        return ReimbursementResponseDto.FromEntity(entity);
    }

    public async Task<List<ReimbursementResponseDto>> GetAllAsync(string? status, string? employeeName)
    {
        var query = db.ReimbursementRequests.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(status))
        {
            var parsed = ParseStatus(status);
            query = query.Where(r => r.Status == parsed);
        }

        if (!string.IsNullOrWhiteSpace(employeeName))
        {
            var name = employeeName.Trim();
            query = query.Where(r => r.EmployeeName == name);
        }

        var items = await query
            .OrderByDescending(r => r.CreatedAtUtc)
            .ThenByDescending(r => r.Id)
            .ToListAsync();

        return items.Select(ReimbursementResponseDto.FromEntity).ToList();
    }

    public async Task<ReimbursementResponseDto> GetByIdAsync(int id)
    {
        var entity = await db.ReimbursementRequests.AsNoTracking().FirstOrDefaultAsync(r => r.Id == id)
                     ?? throw NotFound(id);
        return ReimbursementResponseDto.FromEntity(entity);
    }

    public async Task<ReimbursementResponseDto> ApproveAsync(int id)
    {
        var entity = await FindPendingAsync(id);

        entity.Status = ReimbursementStatus.Approved;
        entity.DecidedAtUtc = DateTime.UtcNow;
        await db.SaveChangesAsync();

        return ReimbursementResponseDto.FromEntity(entity);
    }

    public async Task<ReimbursementResponseDto> RejectAsync(int id, string? reason)
    {
        // El motivo se valida antes de tocar la base: un rechazo sin motivo nunca cambia nada.
        var cleanReason = Require(reason, "El motivo de rechazo es obligatorio.", 500, "El motivo de rechazo");
        var entity = await FindPendingAsync(id);

        entity.Status = ReimbursementStatus.Rejected;
        entity.RejectionReason = cleanReason;
        entity.DecidedAtUtc = DateTime.UtcNow;
        await db.SaveChangesAsync();

        return ReimbursementResponseDto.FromEntity(entity);
    }

    private async Task<ReimbursementRequest> FindPendingAsync(int id)
    {
        var entity = await db.ReimbursementRequests.FirstOrDefaultAsync(r => r.Id == id)
                     ?? throw NotFound(id);

        if (entity.Status != ReimbursementStatus.Pending)
            throw new ConflictException(
                $"La solicitud {id} ya está en estado {entity.Status} y no puede cambiar.");

        return entity;
    }

    private static ReimbursementStatus ParseStatus(string status)
    {
        var value = status.Trim();
        var isNumber = int.TryParse(value, out _);
        if (isNumber || !Enum.TryParse<ReimbursementStatus>(value, ignoreCase: true, out var parsed))
            throw new ValidationException($"Estado '{status}' no válido. Use Pending, Approved o Rejected.");
        return parsed;
    }

    private static NotFoundException NotFound(int id) =>
        new($"No existe una solicitud con id {id}.");

    private static string Require(string? value, string emptyMessage, int maxLength, string fieldLabel)
    {
        if (string.IsNullOrWhiteSpace(value))
            throw new ValidationException(emptyMessage);

        var trimmed = value.Trim();
        if (trimmed.Length > maxLength)
            throw new ValidationException($"{fieldLabel} admite máximo {maxLength} caracteres.");

        return trimmed;
    }
}

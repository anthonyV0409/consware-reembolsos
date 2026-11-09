using Consware.Reimbursements.Api.DTOs;
using Consware.Reimbursements.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace Consware.Reimbursements.Api.Controllers;

/// <summary>
/// Expone la API HTTP. Las reglas de negocio viven en IReimbursementService;
/// las excepciones de negocio se traducen a 400/404/409 en ExceptionHandlingMiddleware.
/// </summary>
[ApiController]
[Route("api/reimbursements")]
public class ReimbursementsController(IReimbursementService service) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<ReimbursementResponseDto>> Create([FromBody] CreateReimbursementDto dto)
    {
        var created = await service.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }

    [HttpGet]
    public async Task<ActionResult<List<ReimbursementResponseDto>>> GetAll(
        [FromQuery] string? status,
        [FromQuery] string? employeeName)
        => Ok(await service.GetAllAsync(status, employeeName));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ReimbursementResponseDto>> GetById(int id)
        => Ok(await service.GetByIdAsync(id));

    [HttpPatch("{id:int}/approve")]
    public async Task<ActionResult<ReimbursementResponseDto>> Approve(int id)
        => Ok(await service.ApproveAsync(id));

    [HttpPatch("{id:int}/reject")]
    public async Task<ActionResult<ReimbursementResponseDto>> Reject(int id, [FromBody] RejectReimbursementDto dto)
        => Ok(await service.RejectAsync(id, dto.Reason));
}

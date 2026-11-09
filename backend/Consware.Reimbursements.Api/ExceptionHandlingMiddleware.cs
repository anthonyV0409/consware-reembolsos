using Consware.Reimbursements.Api.DTOs;
using Consware.Reimbursements.Api.Exceptions;

namespace Consware.Reimbursements.Api;

/// <summary>Traduce excepciones a respuestas JSON { "message": "..." } con el código HTTP correcto.</summary>
public class ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (Exception ex)
        {
            var (status, message) = ex switch
            {
                ValidationException => (StatusCodes.Status400BadRequest, ex.Message),
                NotFoundException => (StatusCodes.Status404NotFound, ex.Message),
                ConflictException => (StatusCodes.Status409Conflict, ex.Message),
                _ => (StatusCodes.Status500InternalServerError, "Ocurrió un error inesperado en el servidor.")
            };

            if (status == StatusCodes.Status500InternalServerError)
                logger.LogError(ex, "Error no controlado");

            if (context.Response.HasStarted) throw;

            // No se usa Response.Clear() para no borrar las cabeceras CORS ya agregadas.
            context.Response.StatusCode = status;
            await context.Response.WriteAsJsonAsync(new ErrorResponseDto(message));
        }
    }
}

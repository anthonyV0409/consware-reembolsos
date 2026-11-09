namespace Consware.Reimbursements.Api.Exceptions;

/// <summary>Datos de entrada inválidos → 400.</summary>
public class ValidationException(string message) : Exception(message);

/// <summary>Recurso inexistente → 404.</summary>
public class NotFoundException(string message) : Exception(message);

/// <summary>Transición de estado no permitida → 409.</summary>
public class ConflictException(string message) : Exception(message);

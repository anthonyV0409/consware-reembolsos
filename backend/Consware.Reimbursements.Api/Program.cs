using Consware.Reimbursements.Api;
using Consware.Reimbursements.Api.Data;
using Consware.Reimbursements.Api.DTOs;
using Consware.Reimbursements.Api.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddControllers()
    .ConfigureApiBehaviorOptions(options =>
    {
        // Errores de formato (JSON mal formado, tipos incorrectos) con el mismo formato { message }.
        options.InvalidModelStateResponseFactory = context =>
        {
            var first = context.ModelState
                .Where(e => e.Value?.Errors.Count > 0)
                .Select(e => e.Value!.Errors[0].ErrorMessage)
                .FirstOrDefault(m => !string.IsNullOrWhiteSpace(m));

            return new BadRequestObjectResult(new ErrorResponseDto(
                "Solicitud inválida: revise el formato de los datos enviados."
                + (first is null ? "" : $" Detalle: {first}")));
        };
    });

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<IReimbursementService, ReimbursementService>();

// Desarrollo: se permite cualquier origen localhost (Angular en :4200, Flutter Web en puerto aleatorio).
builder.Services.AddCors(options =>
    options.AddPolicy("LocalClients", policy =>
        policy.SetIsOriginAllowed(origin =>
                Uri.TryCreate(origin, UriKind.Absolute, out var uri)
                && (uri.Host == "localhost" || uri.Host == "127.0.0.1"))
            .AllowAnyHeader()
            .AllowAnyMethod()));

var app = builder.Build();

// Aplica migraciones pendientes al iniciar (crea la base si no existe).
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    if (!db.Database.GetMigrations().Any())
        throw new InvalidOperationException(
            "No hay migraciones EF Core. Ejecute primero: dotnet ef migrations add InitialCreate");
    db.Database.Migrate();
}

app.UseCors("LocalClients");
app.UseMiddleware<ExceptionHandlingMiddleware>();
app.MapControllers();
app.MapGet("/", () => Results.Redirect("/api/reimbursements"));

app.Run();

# Consware · Sistema de reembolso de gastos

MVP con tres partes que comparten una única API:

| Parte | Tecnología | Carpeta | Estado |
|---|---|---|---|
| API REST + base SQL | ASP.NET Core 8, EF Core 8, SQL Server | `backend/` | Completa |
| App del empleado | Flutter (Material 3, `http`) | `mobile/` | Completa |
| Panel del aprobador | Angular 19 (standalone, signals) | `web/` | Completa |

**Regla de negocio (vive solo en el backend, `ReimbursementService`):**
- Monto ≤ $500.000 COP → `Approved` al crearse. Monto > $500.000 → `Pending`.
- Rechazar exige motivo no vacío. Aprobar/rechazar solo sobre `Pending`; un estado final no cambia (409).

---

## 1. Requisitos previos

- SQL Server accesible (probado contra la instancia local `JEREMY\MSSQLSERVER2026`).
- .NET SDK 8 o superior **con el runtime 8** (`dotnet --list-runtimes` debe mostrar `Microsoft.AspNetCore.App 8.x`).
  Si solo tiene .NET 9/10: cambie `<TargetFramework>` en el `.csproj` a `net9.0`/`net10.0` y las versiones de los paquetes `Microsoft.EntityFrameworkCore.*` a la misma versión mayor.
- Flutter SDK 3.22+ y un emulador Android (o Chrome / Windows desktop).
- Node.js 18.19+ / 20+ y npm.

## 2. Base de datos y API (`backend/`)

1. Ajuste la cadena de conexión en `backend/Consware.Reimbursements.Api/appsettings.json` si su instancia es otra:
   ```json
   "DefaultConnection": "Server=SU_EQUIPO\\SU_INSTANCIA;Database=ConswareReembolsosDB;Trusted_Connection=True;TrustServerCertificate=True;"
   ```
   (`Server=.` o `Server=localhost` para la instancia por defecto; `(localdb)\\MSSQLLocalDB` para LocalDB.)

2. Cree la base con migraciones EF Core:
   ```bash
   cd backend/Consware.Reimbursements.Api
   dotnet tool install --global dotnet-ef --version 8.0.11   # si no lo tiene
   dotnet ef migrations add InitialCreate
   dotnet ef database update
   ```
   Esto crea `ConswareReembolsosDB` y la tabla `dbo.ReimbursementRequests` (con CHECK constraints e índices).
   Si su usuario de Windows no puede crear bases, cree una vacía en SSMS y vuelva a ejecutar `dotnet ef database update`.

3. Ejecute la API:
   ```bash
   dotnet run --urls http://0.0.0.0:5000
   ```
   Pruebe `http://localhost:5000/api/reimbursements` (debe devolver `[]`).
   El archivo `requests.http` contiene las pruebas de la matriz (VS Code REST Client / Visual Studio / Rider).

### Endpoints

| Método | Ruta | Respuestas |
|---|---|---|
| POST | `/api/reimbursements` | 201 (+ `Location`), 400 |
| GET | `/api/reimbursements?status=Pending&employeeName=Empleado%20Demo` | 200 (lista, `[]` si vacía), 400 si el estado no existe |
| GET | `/api/reimbursements/{id}` | 200, 404 |
| PATCH | `/api/reimbursements/{id}/approve` | 200, 404, 409 |
| PATCH | `/api/reimbursements/{id}/reject` body `{"reason":"..."}` | 200, 400, 404, 409 |

Errores siempre con el formato `{"message": "..."}`; los 500 no exponen detalles de SQL Server.

## 3. App Flutter (`mobile/`)

El repositorio incluye `lib/` y `pubspec.yaml`; las carpetas de plataforma se generan una vez:

```bash
cd mobile
flutter create . --project-name consware_reimbursements_mobile --platforms android,web,windows
flutter pub get
```
`flutter create .` no sobrescribe `lib/` ni `pubspec.yaml`. Después, solo para Android, abra
`android/app/src/main/AndroidManifest.xml` y agregue `android:usesCleartextTraffic="true"` a la etiqueta `<application>`
(permite HTTP local en desarrollo):
```xml
<application android:usesCleartextTraffic="true" android:label="..." ...>
```
Luego ejecute `flutter run`.

URL de la API (`lib/config/api_config.dart`), elegida automáticamente:
- Emulador Android → `http://10.0.2.2:5000/api/reimbursements`
- Chrome / Windows / iOS Simulator → `http://localhost:5000/api/reimbursements`
- Celular físico → `flutter run --dart-define=API_BASE_URL=http://<IP-DEL-PC>:5000/api/reimbursements` (abra el puerto 5000 en el Firewall).

Empleado fijo: `Empleado Demo` (el enunciado permite no implementar login).

## 4. Panel Angular (`web/`)

```bash
cd web
npm install
npm start            # http://localhost:4200
```
La API permite CORS desde cualquier `http://localhost:*` (Angular y Flutter Web).

## 5. Recorrido de prueba end-to-end

1. Flutter → Nuevo gasto → $650.000, Alimentación, "Almuerzo con cliente" → aparece **Pendiente**.
2. Flutter → $300.000 → aparece **Aprobada** de inmediato.
3. Angular → filtro Pendientes → Rechazar la de $650.000 (intente sin motivo: el botón queda bloqueado) → escriba motivo.
4. Flutter → Actualizar → la solicitud aparece **Rechazada** con el motivo.
5. Angular → filtro Todas → no hay botones sobre estados finales; vía `requests.http` un PATCH sobre ella da **409**.
6. Detenga y reinicie la API → los datos siguen en SQL Server (`SELECT * FROM dbo.ReimbursementRequests`).
7. Con la API apagada, Flutter muestra "No se pudo conectar con el servidor" con botón Reintentar.

## 6. Decisiones técnicas

- **SQL Server + EF Core con migraciones:** estaba disponible localmente; `DECIMAL(18,2)` para dinero; el esquema lo define el modelo (no scripts manuales). La API aplica migraciones pendientes al arrancar.
- **Una tabla, empleado como texto:** el enunciado no exige usuarios ni login; se agregó índice por `EmployeeName` y `Status` (los filtros).
- **Capas Controller → Service → DbContext:** el controller solo traduce HTTP; la política de $500.000 y las transiciones están en `ReimbursementService`. Las excepciones de negocio (`ValidationException`, `NotFoundException`, `ConflictException`) se convierten a 400/404/409 en un middleware.
- **Defensa en profundidad:** CHECK constraints en SQL (monto > 0, estados válidos, motivo obligatorio al rechazar) además de la validación del servicio.
- **DTOs:** no se exponen entidades EF; el estado viaja como texto (`Pending/Approved/Rejected`), fechas en UTC con `Z`.
- **Flutter con `setState`:** dos pantallas no justifican BLoC/Riverpod; los errores de red, timeout (10 s), HTTP y JSON se traducen a `ApiException` con mensajes legibles.
- **Angular standalone + signals**, una sola pantalla; el rechazo valida el motivo en la UI y el backend lo vuelve a validar.

## 7. Fuera de alcance (y cómo se haría)

- Autenticación/roles (JWT + políticas `Empleado`/`Aprobador`).
- Concurrencia entre aprobadores (columna `rowversion` + `DbUpdateConcurrencyException` → 409).
- Pruebas automatizadas (xUnit sobre `ReimbursementService` con SQLite in-memory; widget tests en Flutter).
- Adjuntar recibos, auditoría de cambios, paginación, Swagger/OpenAPI.

## 8. Uso de IA

> Edite esta sección para que refleje exactamente lo que usted hizo.

Usé Claude (Anthropic) para generar la estructura inicial del proyecto a partir de mi guía técnica: entidades, servicio, controller, pantallas Flutter y el panel Angular. Revisé y ejecuté el código, verifiqué los casos de la matriz de pruebas (límite 500.000/500.001, 400, 404, 409, persistencia tras reinicio) y puedo explicar y modificar cada parte.

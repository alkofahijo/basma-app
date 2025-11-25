Refactor summary — controllers extraction

What I changed
- Extracted business logic from large router modules into `app/controllers/*`.
  - Controllers added: reports, auth, accounts, uploads, locations, ai_reports, admin_* controllers, governments, districts, areas, report_lookups.
- Replaced router bodies with thin delegators that call controllers while preserving:
  - Endpoint paths and HTTP methods
  - Request/response shapes and Pydantic models
  - Status codes and error messages (Arabic messages preserved)
- Added middleware:
  - `app/middlewares/logging_middleware.py` (request/response logging)
  - `app/middlewares/error_middleware.py` (centralized 500 handler)
- Added `app/services/db_helpers.py` with `get_or_create_*` helpers and refactored AI controller to use them.

Why
- Improves maintainability and testability while keeping full backward compatibility for frontends.

Next recommended steps
- Run full test suite and smoke-test critical endpoints.
- Optionally add unit tests for controller functions.
- Small docs or developer guide for the controller pattern.

Notes
- No API routes or schemas were changed. Routers still expose the same response models.
- Arabic user-facing messages left intact where they are returned to clients.

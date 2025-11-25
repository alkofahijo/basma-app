from __future__ import annotations

import traceback
from typing import Callable

from starlette.requests import Request
from starlette.responses import JSONResponse
from starlette.types import ASGIApp
from fastapi import status


class ErrorHandlingMiddleware:
    """Centralized error handling middleware.

    - Lets `HTTPException` bubble through (FastAPI will format it).
    - Catches other exceptions, logs a traceback, and returns a generic
      500 JSON response to avoid leaking internals.
    """

    def __init__(self, app: ASGIApp):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        request = Request(scope, receive=receive)
        try:
            await self.app(scope, receive, send)
        except Exception as exc:  # noqa: BLE001 - intentionally broad to centralize
            # Log the error with traceback to stdout/stderr so ops can collect it.
            tb = traceback.format_exc()
            print("Unhandled exception in request:", request.method, request.url)
            print(tb)

            # Return a safe JSON response. Keep shape consistent with FastAPI's
            # default error responses ({"detail": ...}). Use Arabic message.
            payload = {"detail": "حدث خطأ داخلي في الخادم."}
            response = JSONResponse(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, content=payload)
            await response(scope, receive, send)

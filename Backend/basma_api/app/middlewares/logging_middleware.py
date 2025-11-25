from __future__ import annotations

import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger("basma.middleware")


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:  # type: ignore[override]
        try:
            logger.debug(f"{request.method} {request.url}")
            response = await call_next(request)
            logger.debug(f"Response status: {response.status_code} for {request.method} {request.url}")
            return response
        except Exception as exc:
            # Log full exception and re-raise so existing handlers keep behavior
            logger.exception("Unhandled exception during request processing")
            raise

import time
import uuid
from logging import INFO

from fastapi import Request, Response
from opentelemetry import trace
from starlette.concurrency import iterate_in_threadpool
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.logging import setup_logging


class InsightsMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, req: Request, call_next: callable) -> Response:
        logger, tracer = setup_logging(log_level=INFO)
        correlation_id = req.headers.get("X-Correlation-ID", str(uuid.uuid4()))
        tracer = trace.get_tracer(__name__)
        reqbody: str = await req.json()
        logger.info(reqbody)
        with tracer.start_as_current_span("request") as span:
            span.set_attribute("correlation_id", correlation_id)
            span.set_attribute("http.method", req.method)
            span.set_attribute("http.url", req.url)
            span.set_attribute("http.request.body", reqbody)
            logger.info(f"Request {req.url.path} - Correlation ID: {correlation_id}")
            try:
                start_time = time.perf_counter()
                response = await call_next(req)
                process_time = time.perf_counter() - start_time
                span.set_attribute("processed_time", str(process_time))
                response.headers["X-Correlation-ID"] = correlation_id

                res_body = [section async for section in response.body_iterator]
                response.body_iterator = iterate_in_threadpool(iter(res_body))
                # Stringified response body object
                res_body = res_body[0].decode()
                span.set_attribute("response.body", res_body)
                return response
            except Exception as e:
                span.record_exception(e)
                logger.error("MAIN::Request %s failed: %s", correlation_id, str(e))
                return Response(status_code=500)

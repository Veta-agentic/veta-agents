import logging
import os
from logging import StreamHandler, getLogger
from typing import Optional, Tuple

from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry import trace


def setup_logging(log_level: int = logging.INFO) -> Tuple[logging.Logger, Optional[trace.Tracer]]:
    connection_string = os.getenv("APPINSIGHTS_CONNECTION_STRING")
    app_name = "app"

    # Initialize logger and tracer
    logger = getLogger(app_name)
    # Set log level
    logger.setLevel(log_level)

    # Add console handler
    console_handler = StreamHandler()
    console_handler.setLevel(log_level)
    formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    # Set log level
    logger.setLevel(log_level)

    if connection_string:
        try:
            logger.info("Setting up App Insights.")

            configure_azure_monitor(
                connection_string=connection_string,
                logger_name=app_name,
                role_name="veta-agents",
                enable_live_metrics=True,
                instrumentation_options={
                    "azure_sdk": {"enabled": True},
                    "fastapi": {"enabled": True},
                    "requests": {"enabled": True},
                    "logging": {"enabled": True},
                },
            )

            # Initialize logger and tracer
            tracer = trace.get_tracer(app_name)
            return logger, tracer

        except Exception as e:
            logger.error(f"Error setting up App Insights: {e}")
            return logger, None

    else:
        logger.info("App Insights not configured, using console logging.")
        return logger, None

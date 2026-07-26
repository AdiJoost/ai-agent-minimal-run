import logging
import os


def setupLogging():
    logLevel = os.getenv("LOG_LEVEL", "INFO").upper()
    logFile = os.getenv("LOG_FILE", None)  # e.g. "app.log"

    handlers = [logging.StreamHandler()]  # console

    if logFile:
        os.makedirs(os.path.dirname(logFile), exist_ok=True)
        handlers.append(logging.FileHandler(logFile))

    logging.basicConfig(
        level=logLevel,
        format="%(asctime)s %(levelname)-8s [%(name)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        handlers=handlers,
    )

    # Suppress noisy third-party loggers
    for name in ("httpcore", "httpx", "anthropic", "mcp"):
        logging.getLogger(name).setLevel(logging.WARNING)

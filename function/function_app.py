import json
import logging
import uuid
from datetime import datetime, timezone

import azure.functions as func

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)


@app.route(route="message", methods=["POST"])
def post_message(req: func.HttpRequest) -> func.HttpResponse:
    """
    Accepts a POST request with a JSON payload containing a 'message' field.
    Returns the original message, a UTC timestamp, and a unique request ID.

    mTLS is enforced at the Azure platform level (client_certificate_mode = Required)
    so by the time this function executes, the client certificate has already
    been validated by the App Service platform.
    """
    request_id = str(uuid.uuid4())
    logging.info("Processing request %s", request_id)

    # Parse body
    try:
        body = req.get_json()
    except ValueError:
        logging.warning("Request %s: invalid JSON body", request_id)
        return func.HttpResponse(
            json.dumps({
                "error": "Invalid JSON body",
                "request_id": request_id,
            }),
            status_code=400,
            mimetype="application/json",
        )

    # ── Validate required field 
    message = body.get("message") if isinstance(body, dict) else None

    if message is None:
        logging.warning("Request %s: missing 'message' field", request_id)
        return func.HttpResponse(
            json.dumps({
                "error": "Missing required field: 'message'",
                "request_id": request_id,
            }),
            status_code=422,
            mimetype="application/json",
        )

    if not isinstance(message, str) or not message.strip():
        logging.warning("Request %s: 'message' must be a non-empty string", request_id)
        return func.HttpResponse(
            json.dumps({
                "error": "'message' must be a non-empty string",
                "request_id": request_id,
            }),
            status_code=422,
            mimetype="application/json",
        )

    # Success response
    response_body = {
        "message": message,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "request_id": request_id,
    }

    logging.info("Request %s processed successfully", request_id)

    return func.HttpResponse(
        json.dumps(response_body),
        status_code=200,
        mimetype="application/json",
    )

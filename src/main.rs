use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    response::IntoResponse,
    routing::{get, post},
    Router,
};
use sha2::{Digest, Sha256};
use std::{
    env,
    net::SocketAddr,
    sync::Arc,
};
use tokio::net::TcpListener;
use tracing::{error, info, warn};

#[derive(Clone)]
struct AppState {
    /// SHA-256 hex digest of the expected Telegram webhook secret.
    expected_secret_hash: Arc<String>,
}

/// The official Ironclaw Telegram v2 webhook path.
/// Ironclaw uses `/webhook/telegram-v2/{installation_id}`,
/// and the default installation ID is `"default"`.
const TELEGRAM_V2_PATH: &str = "/webhook/telegram-v2/default";

#[tokio::main]
async fn main() {
    // Render injects PORT (defaults to 10000) and expects you to bind 0.0.0.0.
    let port: u16 = env::var("PORT")
        .unwrap_or_else(|_| "10000".to_string())
        .parse()
        .expect("PORT must be a valid u16");
    let addr = SocketAddr::from(([0, 0, 0, 0], port));

    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info".into()),
        )
        .init();

    // Read the raw webhook secret from an environment variable.
    // On Render, set TELEGRAM_WEBHOOK_SECRET in the dashboard.
    let raw_secret = env::var("TELEGRAM_WEBHOOK_SECRET")
        .expect("TELEGRAM_WEBHOOK_SECRET must be set");

    // Compute SHA-256 hex digest.
    let mut hasher = Sha256::new();
    hasher.update(raw_secret.as_bytes());
    let secret_hash = hex::encode(hasher.finalize());

    // ⬇️ Print the SHA-256 hash to the logs so you can copy it.
    info!(
        sha256_hex = %secret_hash,
        "SHA-256 hash of TELEGRAM_WEBHOOK_SECRET — copy this value"
    );

    let state = AppState {
        expected_secret_hash: Arc::new(secret_hash),
    };

    let app = Router::new()
        .route("/health", get(health_check))
        .route(TELEGRAM_V2_PATH, post(handle_telegram_webhook))
        .with_state(state);

    let listener = TcpListener::bind(addr).await.expect("failed to bind");
    info!(%addr, "Telegram webhook gateway listening");
    axum::serve(listener, app).await.expect("server error");
}

/// Lightweight liveness/readiness probe.
/// Returns `200 OK` with body `ok` when the service is up.
/// Render's health check can point at `/health`.
async fn health_check() -> impl IntoResponse {
    (StatusCode::OK, "ok")
}

/// Handles incoming Telegram updates.
async fn handle_telegram_webhook(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> impl IntoResponse {
    let received_token = headers
        .get("x-telegram-bot-api-secret-token")
        .and_then(|v| v.to_str().ok());

    let Some(received) = received_token else {
        warn!("missing X-Telegram-Bot-Api-Secret-Token header");
        return StatusCode::UNAUTHORIZED.into_response();
    };

    let mut hasher = Sha256::new();
    hasher.update(received.as_bytes());
    let received_hash = hex::encode(hasher.finalize());

    if constant_time_eq(received_hash.as_bytes(), state.expected_secret_hash.as_bytes()) {
        info!("Telegram webhook authenticated successfully");
        StatusCode::OK.into_response()
    } else {
        warn!("Telegram webhook authentication failed — secret hash mismatch");
        StatusCode::UNAUTHORIZED.into_response()
    }
}

/// A simple constant-time byte comparison (avoids early-exit timing leaks).
fn constant_time_eq(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut diff = 0u8;
    for (x, y) in a.iter().zip(b.iter()) {
        diff |= x ^ y;
    }
    diff == 0
}

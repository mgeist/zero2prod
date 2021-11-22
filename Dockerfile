# Builder stage
FROM rust:1.56 AS builder

ENV SQLX_OFFLINE true

WORKDIR /app

COPY . .

RUN cargo build --release

# Runtime stage
FROM debian:bullseye-slim AS runtime

ENV APP_ENVIRONMENT production

WORKDIR /app

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends openssl \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/zero2prod zero2prod
COPY configuration configuration

ENTRYPOINT ["./zero2prod"]

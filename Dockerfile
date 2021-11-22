# Builder stage
FROM lukemathwalker/cargo-chef:latest-rust-1.56 AS chef
WORKDIR /app

FROM chef AS planner
COPY . .
# create lock-like file
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json

# build project dependencies
RUN cargo chef cook --release --recipe-path recipe.json

COPY . .

ENV SQLX_OFFLINE true

RUN cargo build --release --bin zero2prod

# Runtime stage
FROM debian:bullseye-slim AS runtime

WORKDIR /app

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends openssl \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/zero2prod zero2prod
COPY configuration configuration

ENV APP_ENVIRONMENT production

ENTRYPOINT ["./zero2prod"]

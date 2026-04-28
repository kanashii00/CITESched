# Combined build stage.
# This image includes both Dart and Flutter so Render can rebuild the
# server binary and the Flutter web app from the same Git commit.
FROM ghcr.io/cirruslabs/flutter:stable AS build

ARG CITESCHED_SERVER_URL=https://citesched.onrender.com/
ARG GOOGLE_WEB_CLIENT_ID=747757509128-4rqonmqfqp1s8i1f7pafedc7988jk48r.apps.googleusercontent.com

WORKDIR /src
COPY . .

WORKDIR /src/citesched_server
RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/server

WORKDIR /src/citesched_flutter
RUN flutter pub get
RUN flutter build web \
    --base-href /app/ \
    --wasm \
    --dart-define=CITESCHED_SERVER_URL=${CITESCHED_SERVER_URL} \
    --dart-define=GOOGLE_WEB_CLIENT_ID=${GOOGLE_WEB_CLIENT_ID} \
    --output /tmp/citesched-web

# Final stage
FROM debian:stable-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gettext-base \
    libc6 \
    libstdc++6 \
    netcat-openbsd \
    nginx \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /src/citesched_server/bin/server /app/server
COPY --from=build /src/citesched_server/config/ /app/config/
COPY --from=build /src/citesched_server/deploy/render/start.sh /app/start.sh
COPY --from=build /src/citesched_server/deploy/render/nginx.conf /app/nginx.conf
COPY --from=build /src/citesched_server/web/ /app/web/
COPY --from=build /tmp/citesched-web/ /app/web/app/
COPY --from=build /src/citesched_server/migrations/ /app/migrations/
COPY --from=build /src/citesched_server/lib/src/generated/protocol.yaml /app/lib/src/generated/protocol.yaml

EXPOSE 10000

RUN chmod +x /app/start.sh
CMD ["/app/start.sh"]

FROM golang:1.23-alpine AS builder

RUN apk --update upgrade \
&& apk --no-cache --no-progress add git make gcc musl-dev \
&& rm -rf /var/cache/apk
RUN git clone --depth 1 https://github.com/emersion/hydroxide /opt/hydroxide

## Patch for iOS to work with Hydroxide
RUN sed -ie '310,313d' /opt/hydroxide/imap/mailbox.go

WORKDIR /opt/hydroxide
RUN CGO_ENABLED=1 go build -o /bin/hydroxide /opt/hydroxide/cmd/hydroxide


FROM alpine:latest

LABEL version="0.2.30"
LABEL org.opencontainers.image.authors="code@kshdev.slmail.me"
LABEL org.opencontainers.image.source="https://github.com/ksharizard/docker-hydroxide"
LABEL description="A third-party, open-source ProtonMail CardDAV, IMAP and SMTP bridge"

RUN addgroup -S hydroxide_group && adduser -S hydroxide -G hydroxide_group

COPY --from=builder /bin/hydroxide /usr/local/bin/hydroxide

RUN mkdir -p /home/hydroxide/.config/hydroxide && \
    chown -R hydroxide:hydroxide_group /home/hydroxide/.config

# Switch to the non-root user
USER hydroxide

# Set the working directory to the user's home directory
WORKDIR /home/hydroxide

# Expose the ports the application listens on
EXPOSE 8080/tcp
EXPOSE 1143/tcp
EXPOSE 1025/tcp

# Define the volume for persistent configuration data
VOLUME [ "/home/hydroxide/.config/hydroxide" ]

# Set the default command to run when the container starts
# The binary is in the PATH, so we can call it directly
CMD ["hydroxide", "serve"]

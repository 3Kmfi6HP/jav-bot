# Build stage
FROM alpine AS builder

# Install build dependencies
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk --no-cache add shc gcc make wget upx bash musl-dev

# Set working directory for the build
WORKDIR /build

# Copy necessary files for the build
COPY telegram.bot script.sh ./

# Compile Bash script and Telegram bot script to binary
RUN shc -r -f script.sh && mv script.sh.x script && rm -f script.sh script.sh.x.c \
    && shc -r -f telegram.bot && mv telegram.bot.x telegram.bot && rm -f telegram.bot.x.c

# Download, extract, and clean up gost
RUN wget -nv -O gost.tar.gz https://github.com/go-gost/gost/releases/download/v3.0.0-rc8/gost_3.0.0-rc8_linux_amd64v3.tar.gz \
    && tar -xzvf gost.tar.gz && chmod +x gost && upx -9 gost && rm -f gost.tar.gz *.md

# Final stage
FROM alpine

# Install runtime dependencies
RUN apk --no-cache add curl jq ffmpeg bash

# Create and set working directory
WORKDIR /app

# Copy compiled binary and other necessary files from the build stage
COPY --from=builder /build/ ./

# Create a new user
RUN adduser -D -u 1000 user1000

# Change ownership to user with uid 1000
RUN chown -R user1000:user1000 /app

# Switch to the new user
USER 1000

# Set health check
HEALTHCHECK --interval=2m --timeout=30s CMD wget --no-verbose --tries=1 --spider ${SPACE_HOST} || exit 1

# Expose port
EXPOSE 7860

# Run the binary
CMD ["./script"]

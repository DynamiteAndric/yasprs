FROM node:20-alpine

RUN apk add --no-cache su-exec

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

# readable by whatever PUID/PGID the app runs as, regardless of host file modes
# (set on copy: a chmod -R layer would duplicate every file it touches)
COPY --chmod=755 server.js ./
COPY --chmod=755 src ./src

COPY entrypoint.sh /entrypoint.sh
# strip CRLF in case the script was checked out on Windows
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

# config lives in $XDG_CONFIG_HOME/yasprs/profile.json
ENV NODE_ENV=production \
    PORT=3001 \
    XDG_CONFIG_HOME=/config \
    PUID=1000 \
    PGID=1000
RUN mkdir -p /config /pkgs

EXPOSE 3001

ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", "server.js"]

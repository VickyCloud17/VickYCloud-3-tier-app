# ─────────────────────────────────────────────────────────────────
#  VickYCloud — Web Tier Dockerfile
#  Base:    nginx:alpine
#  Serves:  index.html, login.html (static)
#           Proxies /submit.php, /login.php → app-service
# ─────────────────────────────────────────────────────────────────

FROM nginx:alpine

# ── Security: remove default nginx page ──────────────────────
RUN rm -rf /usr/share/nginx/html/*

# ── Copy static frontend files ────────────────────────────────
COPY index.html   /usr/share/nginx/html/index.html
COPY login.html   /usr/share/nginx/html/login.html

# ── Copy nginx config ─────────────────────────────────────────
COPY default.conf /etc/nginx/conf.d/default.conf

# ── Correct ownership ─────────────────────────────────────────
RUN chown -R nginx:nginx /usr/share/nginx/html \
    && chmod -R 755 /usr/share/nginx/html

# ── Health check ──────────────────────────────────────────────
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost/ || exit 1

EXPOSE 80
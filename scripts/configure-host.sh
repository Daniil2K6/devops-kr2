#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/kr2"
sudo -v
mkdir -p "$HOME/kr2-evidence"
sudo ufw status numbered > "$HOME/ufw-before-kr2.txt"
sudo sha256sum /etc/nginx/sites-available/devops-site > "$HOME/kr2-evidence/devops-site.before"
if ! sudo test -f /etc/ssl/private/kr2.key; then
  sudo openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -keyout /etc/ssl/private/kr2.key -out /etc/ssl/certs/kr2.crt \
    -subj '/CN=api.devops.local' -addext 'subjectAltName=DNS:api.devops.local'
fi
sudo chown root:root /etc/ssl/private/kr2.key
sudo chmod 600 /etc/ssl/private/kr2.key
sudo install -m 644 docs/kr2.nginx /etc/nginx/sites-available/kr2
sudo ln -sfn /etc/nginx/sites-available/kr2 /etc/nginx/sites-enabled/kr2
sudo nginx -t
sudo systemctl reload nginx
cp /etc/ssl/certs/kr2.crt "$HOME/kr2.crt"
{
  (cd "$HOME/devops-course-2026" && scripts/audit.sh)
  echo 'AUDIT_EXIT=0'
  diff <(sudo ufw status numbered) "$HOME/ufw-before-kr2.txt"
  echo 'UFW_UNCHANGED'
  sudo sha256sum -c "$HOME/kr2-evidence/devops-site.before"
  sudo ls -l /etc/ssl/private/kr2.key "$HOME/kr2/.env"
  sudo ss -tlnp
} 2>&1 | tee "$HOME/kr2-evidence/server-audit.txt"
echo 'HTTPS_CONFIGURED'

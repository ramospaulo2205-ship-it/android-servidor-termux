#!/data/data/com.termux/files/usr/bin/sh
# Autostart do servidor Termux (Termux:Boot).
# Destino no celular: ~/.termux/boot/start-server.sh
#
# Idempotente: cada serviço só sobe se não estiver vivo, então dá para rodar
# à mão quantas vezes quiser. Os blocos opcionais (status, app, Hermes) só
# rodam se o arquivo do serviço existir. Ajuste as variáveis abaixo.

PREFIX=/data/data/com.termux/files/usr
export PATH="$PREFIX/bin:$PATH"
export HOME=/data/data/com.termux/files/home

LOGS="$HOME/logs"
PGDATA="$PREFIX/var/lib/postgresql"
SSHD_PID="$PREFIX/var/run/sshd.pid"

# Página de status (docs/02). Vazio desliga.
STATUS_PY="$HOME/apps/status/server.py"
STATUS_HOST="127.0.0.1"            # ou o IP do Tailscale; evite 0.0.0.0

# App Python no Debian (docs/06). Pasta vazia ou ausente desliga.
DEBIAN_ROOTFS="$PREFIX/var/lib/proot-distro/containers/debian/rootfs"
APP_DIR="/root/meuapp"             # caminho DENTRO do Debian
APP_CMD="exec .venv/bin/uvicorn meuapp.main:app --host 127.0.0.1 --port 8010"

# Hermes Agent no Debian (docs/07).
HERMES_BIN="/root/hermes-agent/.venv/bin/hermes"

mkdir -p "$LOGS"
log() { echo "$(date '+%F %T') $*" >> "$LOGS/boot.log"; }

# vivo <pidfile> <trecho do cmdline>: o PID existe E é o processo esperado.
# Depois de um reboot o pidfile antigo sobra e o número pode ter sido reusado.
vivo() {
    [ -f "$1" ] || return 1
    pid=$(cat "$1")
    kill -0 "$pid" 2>/dev/null && tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null | grep -q "$2"
}

log "start-server.sh iniciado"

termux-wake-lock

if vivo "$SSHD_PID" sshd; then
    log "sshd já rodando (pid $(cat "$SSHD_PID"))"
else
    sshd && log "sshd iniciado"
fi

if [ -d "$PGDATA" ]; then
    if pg_ctl -D "$PGDATA" status > /dev/null 2>&1; then
        log "postgres já rodando"
    else
        # postmaster.pid órfão de desligamento abrupto: pg_ctl decide se é válido
        pg_ctl -D "$PGDATA" -l "$LOGS/postgres.log" start > /dev/null 2>&1 \
            && log "postgres iniciado" || log "postgres FALHOU ao iniciar"
    fi
fi

if [ -n "$STATUS_PY" ] && [ -f "$STATUS_PY" ]; then
    if vivo "$LOGS/status.pid" server.py; then
        log "status já rodando (pid $(cat "$LOGS/status.pid"))"
    else
        STATUS_HOST="$STATUS_HOST" nohup python "$STATUS_PY" >> "$LOGS/status.log" 2>&1 < /dev/null &
        echo $! > "$LOGS/status.pid"
        log "status iniciado (pid $!)"
    fi
fi

# Serviços do Debian: o nohup ENVOLVE o proot-distro. O proot roda com
# --kill-on-exit; um nohup dentro do login morreria junto com ele.
# O PID guardado é o do proot, que IGNORA o SIGTERM: para parar o serviço,
# mande o sinal ao processo filho dele (docs/04-autostart.md).
if [ -d "$DEBIAN_ROOTFS$APP_DIR" ]; then
    if vivo "$LOGS/app.pid" "$APP_DIR"; then
        log "app já rodando (pid $(cat "$LOGS/app.pid"))"
    else
        nohup proot-distro login debian -- bash -c "cd $APP_DIR && set -a && [ -f .env ] && . ./.env; set +a; $APP_CMD" \
            >> "$LOGS/app.log" 2>&1 < /dev/null &
        echo $! > "$LOGS/app.pid"
        log "app iniciado (pid $!)"
    fi
fi

# Um bot do Telegram aceita UM leitor: se ele roda em outra máquina, pare lá.
if [ -x "$DEBIAN_ROOTFS$HERMES_BIN" ]; then
    if vivo "$LOGS/hermes-gateway.pid" hermes; then
        log "hermes-gateway já rodando (pid $(cat "$LOGS/hermes-gateway.pid"))"
    else
        nohup proot-distro login debian -- "$HERMES_BIN" gateway run \
            >> "$LOGS/hermes-gateway.log" 2>&1 < /dev/null &
        echo $! > "$LOGS/hermes-gateway.pid"
        log "hermes-gateway iniciado (pid $!)"
    fi
fi

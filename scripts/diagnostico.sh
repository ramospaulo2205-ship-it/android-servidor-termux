#!/data/data/com.termux/files/usr/bin/sh
# Diagnóstico do celular antes (e depois) da montagem. Só lê; não instala nada.
# Uso, dentro do Termux:  sh diagnostico.sh [pacote-python ...]
# Sem argumentos, testa uma lista de pacotes com código nativo comuns.

echo "== aparelho"
for k in ro.product.model ro.product.device ro.build.version.release \
         ro.board.platform ro.boot.flash.locked sys.oem_unlock_allowed; do
    echo "$k=$(getprop $k)"
done
echo "arquitetura=$(uname -m)  kernel=$(uname -r)  nucleos=$(nproc)"

echo "== memória (olhe a coluna available) e disco"
free -m
df -h "$HOME" | tail -1

echo "== ferramentas"
for c in python pip node git psql pg_ctl sshd proot-distro curl gpg; do
    if command -v "$c" > /dev/null 2>&1; then
        v=$($c --version 2>&1 | head -1)
        case "$v" in ""|*"invalid option"*|*"illegal option"*) v="presente" ;; esac
        printf '%-13s %s\n' "$c" "$v"
    else
        printf '%-13s AUSENTE\n' "$c"
    fi
done

if command -v python > /dev/null 2>&1; then
    echo "== plataforma do Python do Termux"
    python -c "import sysconfig; print(sysconfig.get_platform())"

    echo "== wheels disponíveis para essa plataforma"
    [ $# -gt 0 ] && pacotes="$*" || pacotes="asyncpg pydantic-core psycopg-binary cryptography pyyaml uvloop jiter markupsafe"
    d=$(mktemp -d)
    for p in $pacotes; do
        if python -m pip download -q --no-deps --only-binary=:all: -d "$d" "$p" > /dev/null 2>&1; then
            echo "$p: baixou $(ls "$d" | grep -i "$(echo "$p" | tr - _)" | head -1)  <- confira se não é versão 0.0.x vazia"
        else
            echo "$p: SEM wheel"
        fi
    done
    rm -rf "$d"
fi

echo "== limite de processos em segundo plano (Android 12+; ajustar pelo adb, docs/01)"
echo "rode no PC: adb shell device_config get activity_manager max_phantom_processes"

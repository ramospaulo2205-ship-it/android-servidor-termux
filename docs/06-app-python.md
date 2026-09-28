# 06 — Uma API Python (FastAPI) no Debian

Exemplo genérico, baseado no que foi feito na referência com uma API FastAPI +
PostgreSQL (Alembic para migrations).

## 1. Banco no Postgres do Termux

```bash
psql -d postgres -c "create role meuapp login password 'troque-isto';"
psql -d postgres -c "create database meuapp owner meuapp;"
```

## 2. Código no Debian

Do PC, sem mexer no seu checkout (`git archive` exporta só o que está
versionado num branch):

```bash
git archive --format=tar main -- src migrations alembic.ini pyproject.toml \
  | ssh -p 8022 <usuario>@<ip> \
    'R=$PREFIX/var/lib/proot-distro/containers/debian/rootfs/root/meuapp; mkdir -p $R && tar -x -C $R'
```

## 3. Ambiente e dependências

```bash
proot-distro login debian -- bash -c '
  cd /root/meuapp &&
  python3 -m venv .venv &&
  .venv/bin/pip install -e .'
```

**Instale com `-e` (editável)** se o projeto lê arquivos por caminho relativo
ao pacote (`sql/`, `templates/`, `rules/`…). Na referência, instalado sem `-e`
o pacote foi copiado para `site-packages` e uma rota deu **500**:
`FileNotFoundError: .../lib/python3.13/sql/<arquivo>.sql`.

O `pip` resolve as versões mais novas que o `pyproject.toml` aceitar; se o
projeto usa `uv.lock` ou `requirements.txt` com versões fixas, instale por eles
para reproduzir o ambiente do PC.

## 4. Configuração e migrations

```bash
proot-distro login debian -- bash -c '
  cd /root/meuapp &&
  printf "DATABASE_URL=postgresql://meuapp:troque-isto@127.0.0.1:5432/meuapp\n" > .env &&
  chmod 600 .env &&
  set -a && . ./.env && set +a &&
  .venv/bin/alembic upgrade head'
```

## 5. Subir e testar

Pelo `start-server.sh` (bloco do app) ou à mão, com o `nohup` do lado de fora
([05](05-debian-proot.md)):

```bash
nohup proot-distro login debian -- bash -c "cd /root/meuapp && set -a && . ./.env && set +a && exec .venv/bin/uvicorn meuapp.main:app --host 127.0.0.1 --port 8010" \
  >> ~/logs/meuapp.log 2>&1 < /dev/null &
echo $! > ~/logs/meuapp.pid
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8010/docs
```

Na referência a API subiu em 4 s e o uvicorn ficou com ~57 MB de RSS.

**Escute em `127.0.0.1`**, não em `0.0.0.0`, se a API não tem login. Do PC,
acesse por túnel SSH ([03](03-tailscale.md)).

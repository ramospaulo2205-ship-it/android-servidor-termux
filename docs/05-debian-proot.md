# 05 — Debian no proot-distro

## Por que

O Python do Termux é compilado para Android e se identifica como
`android-24-arm64_v8a`. O pip só aceita wheels dessa plataforma, e quase
nenhum pacote publica esse tipo de wheel. Medido na referência com
`pip download --only-binary=:all:`:

| Sem wheel Android | Com wheel Android |
|---|---|
| asyncpg, psycopg-binary, cryptography, selectolax, ctranslate2, av, playwright, uvloop, httptools, pyyaml, jiter, markupsafe | só `pydantic-core` — e era um pacote vazio `0.0.1` |

As saídas seriam compilar tudo com `clang`/`rust` no celular (não testado) ou
rodar um Linux comum dentro do Termux. O `proot-distro` faz o segundo sem
root. Dentro do Debian, o pip usa wheels `manylinux aarch64`: na referência,
**todas** as dependências de dois projetos instalaram prontas, sem compilar nada.

O Python do Termux pode também ser **novo demais**: o Hermes Agent exige
`>=3.11,<3.14`, e o Termux tinha 3.14.6. O Debian 13 traz 3.13.5.

## Instalar

```bash
pkg install proot-distro                  # 5.9.0 na referência
proot-distro install debian               # Debian 13.7 na referência
proot-distro login debian -- bash -c 'apt-get update && apt-get install -y python3 python3-venv python3-pip git'
proot-distro login debian -- python3 --version     # 3.13.5
```

## Onde fica o sistema de arquivos

```
$PREFIX/var/lib/proot-distro/containers/debian/rootfs/
```

**Não é `installed-rootfs/`**, que aparece em guias antigos. Na dúvida,
descubra criando um arquivo lá dentro e procurando do lado de fora:

```bash
proot-distro login debian -- touch /root/MARCA
find $PREFIX/var/lib/proot-distro -name MARCA
```

## Rede e isolamento

- O Debian **compartilha a rede** com o Termux: um app no Debian conecta no
  Postgres do Termux por `127.0.0.1:5432`. Não instale um segundo Postgres nem
  um segundo sshd lá dentro.
- Por padrão o Debian **não é isolado** do resto do celular (a ajuda do
  `proot-distro` diz *"By default container is not isolated from the host
  filesystem"*). Um processo lá dentro, rodando como `root` falso, alcança os
  arquivos do Termux.

## Rodar um serviço do Debian em segundo plano

O `proot-distro login` roda com `--kill-on-exit`: quando o login termina, ele
mata os filhos. Então **isto não funciona** (o serviço morre junto com o SSH):

```bash
proot-distro login debian -- bash -c "nohup meu-servico &"      # ERRADO
```

O `nohup` tem de envolver o próprio `proot-distro`:

```bash
nohup proot-distro login debian -- bash -c "cd /root/app && exec .venv/bin/uvicorn ..." \
  >> ~/logs/app.log 2>&1 < /dev/null &
echo $! > ~/logs/app.pid        # PID do proot (para parar, ver docs/04: o proot ignora SIGTERM)
```

Use `exec` no último comando, para o serviço substituir o `bash`.

## Custo

Na referência o processo `proot` ocupa ~3,7 MB. O custo de velocidade da
tradução de chamadas de sistema **não foi medido**.

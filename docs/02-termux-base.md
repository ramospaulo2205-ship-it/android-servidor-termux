# 02 — Termux, SSH e PostgreSQL

## 1. Instalar os apps do F-Droid, não da Play Store

Instale **Termux**, **Termux:API** e **Termux:Boot** do F-Droid. Os três
precisam ter a **mesma assinatura** (a da Play Store é outra e mais antiga).
Na referência: Termux 0.118.3, Termux:API 0.53.0, Termux:Boot 0.8.1.

Abra o Termux:Boot uma vez depois de instalar — é o que registra o app para
receber o aviso de boot, segundo a documentação dele (não verificado nesta
montagem).

## 2. Atualizar tudo antes de instalar qualquer coisa

O Termux é *rolling release*. **Nunca rode `pkg install` avulso com o índice
velho**: na referência, instalar `gnupg` atualizou `libcurl` sem atualizar o
`openssl`, e o `curl` quebrou (`cannot locate symbol
"SSL_set_quic_tls_early_data_enabled"`); depois o `gpg` quebrou pelo mesmo
motivo (`libgcrypt is too old`). O jeito certo:

```bash
apt update
apt-get -s full-upgrade | grep -c '^Inst'     # simula: quantos pacotes mudam
apt-get -s full-upgrade | grep -E '^Remv'     # simula: algo seria removido?
apt-get -y -o Dpkg::Options::=--force-confold full-upgrade
```

`--force-confold` mantém os seus arquivos de configuração (por exemplo, o
`sshd_config`).

## 3. SSH

```bash
pkg install openssh
passwd                 # senha para o primeiro acesso
whoami                 # anote: é o usuário do SSH (algo como u0_a123)
sshd                   # sobe na porta 8022
```

No PC, com o celular na mesma rede ou pelo cabo (`adb forward tcp:8022 tcp:8022`):

```bash
ssh-copy-id -p 8022 <usuario>@<ip-do-celular>     # ou cole a chave em ~/.ssh/authorized_keys
ssh -p 8022 <usuario>@<ip-do-celular>
```

Permissões que o sshd exige: `~/.ssh` com 700 e `authorized_keys` com 600.

## 4. PostgreSQL

```bash
pkg install postgresql
initdb $PREFIX/var/lib/postgresql
# deixe explícito que só escuta localmente:
sed -i.orig "s/^#listen_addresses.*/listen_addresses = 'localhost'/" \
  $PREFIX/var/lib/postgresql/postgresql.conf
pg_ctl -D $PREFIX/var/lib/postgresql -l ~/logs/postgres.log start
psql -d postgres -c 'select version();'
```

O `initdb` do Termux cria o `pg_hba.conf` em modo **`trust`** (qualquer
conexão local entra sem senha). Veja [08](08-seguranca.md) antes de guardar
dado real.

## 5. Página de status (opcional)

[`../scripts/server.py`](../scripts/server.py) responde um JSON com uptime,
memória, disco, temperatura e se o Postgres responde. Só biblioteca padrão.

```bash
mkdir -p ~/apps/status && cp server.py ~/apps/status/
STATUS_HOST=127.0.0.1 python ~/apps/status/server.py
```

Duas coisas que o Android bloqueia para apps (medido no Android 12):
`/proc/uptime` (o script usa `CLOCK_BOOTTIME`, que é o mesmo relógio) e
`/sys/class/thermal` (a temperatura sai `legivel: false`). `/proc/net/tcp`
também é ilegível; para ver portas abertas use `adb shell ss -ltn`.

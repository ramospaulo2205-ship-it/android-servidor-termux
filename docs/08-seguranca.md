# 08 — Segurança

O que ficou aberto na montagem de referência e como fechar.

| Ponto | Risco | Como fechar |
|---|---|---|
| Postgres em `trust` no `127.0.0.1` | qualquer app do Android fala com o localhost; a senha do usuário do banco **não é conferida** | trocar `trust` por `scram-sha-256` no `pg_hba.conf` (as linhas `host`), definir senha em todos os papéis e reiniciar o Postgres |
| Login por senha no SSH | a porta 8022 é alcançável por qualquer aparelho da sua conta Tailscale | com a chave já funcionando: `PasswordAuthentication no` em `$PREFIX/etc/ssh/sshd_config` e reiniciar o `sshd` |
| Debian não isolado | um agente de IA com terminal "local" no Debian alcança os arquivos do Termux, os `.env` e o Postgres | `proot-distro login --isolated`, ou aceitar sabendo disso |
| Página de status em `0.0.0.0` | mostra hostname, memória e disco para quem estiver na mesma Wi-Fi | `STATUS_HOST=127.0.0.1` (padrão do script deste repositório) ou o IP do Tailscale |
| Chaves de API | ficam em `.env` dentro do rootfs do Debian | `chmod 600`; nunca colar a chave em chat, log ou captura de tela |
| API sem login | quem alcança a porta lê os dados | escutar só em `127.0.0.1` e acessar por túnel SSH |

Celular perdido ou roubado: revogue as chaves de API usadas nele. Uma chave
separada por aparelho facilita isso.

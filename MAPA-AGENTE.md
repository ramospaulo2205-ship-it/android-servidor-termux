# Mapa para agentes de IA

Roteiro para um agente de código (Claude Code, Codex, Gemini CLI ou similar)
montar este servidor num celular Android **com uma pessoa ao lado**. O agente
roda no PC dela e fala com o celular por `adb` e por SSH.

A explicação de cada passo está em [`docs/`](docs/). Este arquivo diz **a
ordem, o que perguntar, o que conferir e onde parar**.

## Regras que valem o tempo todo

1. **Meça, não suponha.** Todo número que você reportar (memória, versão,
   tempo, código HTTP) vem de uma saída de comando desta sessão. O que não foi
   medido se escreve "não medido".
2. **Pare nos portões.** Cada fase termina num portão de verificação. Não
   avance se ele falhar; conte à pessoa o que falhou, com a saída real.
3. **Pergunte antes de:** apagar ou sobrescrever arquivo que não foi você que
   criou; qualquer coisa que exija root ou desbloqueio de bootloader (apaga o
   celular: recuse e explique); adicionar repositório apt ou rodar `curl | bash`
   de terceiros; expor porta em `0.0.0.0`; copiar dado pessoal para o celular;
   mexer em serviço que roda em outra máquina (ex.: um bot que já está no ar).
4. **Segredos nunca passam pelo chat.** Chave de API e token são digitados pela
   pessoa no terminal (`read -rsp`) ou copiados de arquivo para arquivo sem
   exibir (`grep ... | ssh ... 'cat >> .env'`). Para conferir, mostre só
   comprimento e prefixo.
5. **Nunca `pkill -f <trecho>` por SSH.** Ele casa com a própria linha de
   comando e derruba a sessão. Use pidfile: `kill $(cat ~/logs/x.pid)` para
   serviço do Termux; para serviço do Debian o pidfile é do `proot`, que ignora
   `SIGTERM` — mate o processo filho ([docs/04](docs/04-autostart.md)) e confira
   que o `proot` saiu.
6. **Nunca `pkg install` avulso** com índice velho: simule e faça
   `full-upgrade` antes (fase 2).
7. **Comando longo vai para segundo plano** (instalação de pacotes, `pip
   install`, `proot-distro install`): alguns levam minutos no celular.
8. **Passo interativo é da pessoa** (`passwd`, `hermes setup`, login do
   Tailscale, aceitar a chave do adb). Dê o comando pronto e espere.

## Variáveis que você vai descobrir

| Variável | Como obter |
|---|---|
| `USUARIO` | `whoami` no Termux (ex.: `u0_a123`) |
| `IP` | app do Tailscale no celular (`100.x.y.z`), ou `adb forward tcp:8022 tcp:8022` + `localhost` |
| `SSH` | `ssh -o BatchMode=yes -p 8022 $USUARIO@$IP` |
| `ROOTFS` | `$PREFIX/var/lib/proot-distro/containers/debian/rootfs` (confirmar na fase 5) |

## Fase 0 — Avaliar ([docs/00](docs/00-avaliar-o-celular.md))

- Pergunte: o que a pessoa quer rodar? (API Python, Hermes, só banco…)
- Rode `scripts/diagnostico.sh` no Termux (a pessoa cola, ou você envia por
  SSH quando a fase 2 estiver pronta) e leia: arquitetura, RAM *available*,
  disco, plataforma do Python, wheels.
- **Portão:** `aarch64`, ≥ ~1 GB *available*, ≥ 10 GB livres. Abaixo disso,
  diga que o aparelho é fraco para o que ela quer, com os números.
- Se ela pedir Docker ou Ubuntu no lugar do Android: explique que exige root
  ou desbloqueio (apaga o celular) e ofereça o Debian no proot.

## Fase 1 — Android ([docs/01](docs/01-preparar-android.md))

- Pessoa: opções de desenvolvedor, depuração USB, bateria "Sem restrições"
  para Termux e Termux:Boot.
- Você: `adb devices` → `device`. Android 12+: os dois `device_config`.
- Conte a ela a limitação do boot antes do primeiro desbloqueio e pergunte
  qual saída prefere.
- **Portão:** `adb shell device_config get activity_manager max_phantom_processes`
  → `2147483647`.

## Fase 2 — Termux, SSH, Postgres ([docs/02](docs/02-termux-base.md))

- Pessoa: instala Termux, Termux:API e Termux:Boot **do F-Droid**, roda
  `pkg install openssh`, `passwd`, `sshd`, `whoami`.
- Você: copia a chave pública do PC, testa `$SSH true`.
- Você: `apt update`, simula `full-upgrade` (conte pacotes e remoções; se
  houver remoção, pergunte), executa com `--force-confold`.
- Você: Postgres (`initdb`, `listen_addresses = 'localhost'`, `pg_ctl start`).
- **Portão:** `$SSH 'pg_isready; psql -d postgres -Atc "select version()"'`.

## Fase 3 — Tailscale ([docs/03](docs/03-tailscale.md))

- Pessoa: instala e loga o app no celular e no PC, na mesma conta.
- **Portão:** `ssh -p 8022 $USUARIO@<ip-tailscale> true` funciona **e**
  `curl -m 5 http://<ip-tailscale>:5432` falha.

## Fase 4 — Autostart ([docs/04](docs/04-autostart.md))

- Copie `scripts/start-server.sh` para `~/.termux/boot/` (leia o que já existe
  lá antes; se existir, mostre a diferença e pergunte).
- Rode-o duas vezes.
- **Portão:** a 2ª execução registra "já rodando" para tudo em `~/logs/boot.log`.
- Reboot real: só com a pessoa presente para desbloquear.

## Fase 5 — Debian ([docs/05](docs/05-debian-proot.md))

- `pkg install proot-distro`, `proot-distro install debian`, Python no Debian.
- Descubra o rootfs real com o arquivo-marca; não confie em caminho de guia.
- **Portão:** `proot-distro login debian -- python3 --version` responde, e o
  rootfs foi confirmado.

## Fase 6 — App Python ([docs/06](docs/06-app-python.md)) — se pedido

- Pergunte: o projeto guarda dado pessoal? Se sim, **não copie dados** sem
  autorização, e feche o `trust` do Postgres antes (fase 8).
- Código por `git archive` (não mexa no checkout da pessoa), `pip install -e .`,
  `.env` com modo 600, migrations, serviço em `127.0.0.1`.
- **Portões:** rotas principais → 200 no celular; do PC, pelo túnel SSH → 200;
  pelo IP do Tailscale → recusado; `start-server.sh` rodado 2× sem duplicar.

## Fase 7 — Hermes ([docs/07](docs/07-hermes-agent.md)) — se pedido

- Instale pelo Git oficial no Debian, num commit fixo (hash de 40 caracteres).
- Pessoa: `ssh -t -p 8022 $USUARIO@$IP hermes setup` (Full setup, backend
  Local, sem navegador/voz). Avise que parece travar e é normal.
- Você: confira a chave pelo comprimento e prefixo, sem exibir;
  `hermes tools disable browser computer_use image_gen bfl tts` (guarde antes
  uma cópia do `config.yaml`); `hermes -z "Responda apenas: OK"`.
- Telegram: pergunte se o bot já roda em outra máquina. Se sim, a escolha é
  dela (mover, bot novo, ou sem gateway); para mover, pare o de lá **antes**.
- **Portões:** `hermes -z` responde; `hermes gateway status` → running; a
  pessoa manda uma mensagem e o bot responde.

## Fase 8 — Segurança ([docs/08](docs/08-seguranca.md))

- Mostre a tabela de riscos e pergunte o que fechar agora. Obrigatório antes de
  dado pessoal: `trust` → `scram-sha-256`.

## Entrega

Ao final, deixe no PC da pessoa (fora deste repositório, que é público):

- `README.md` com usuário, IP, portas, onde fica cada coisa e como parar;
- `PROGRESSO.md` com cada fase, os portões e os números medidos;
- a lista do que ficou pendente (ex.: reboot real não testado).

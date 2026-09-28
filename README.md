# android-servidor-termux

Como transformar um celular Android parado num servidor Linux de bolso, **sem
root**: Termux, SSH, PostgreSQL, Debian via `proot-distro`, apps Python e o
agente [Hermes](https://github.com/NousResearch/hermes-agent), com tudo subindo
sozinho quando o celular liga e acesso remoto pelo Tailscale.

Este repositório nasceu de uma montagem real, num **Moto G31** (Android 12,
MediaTek, 4 GB de RAM), em **2026-09-27**. Todo número aqui foi medido nesse
aparelho, nessa data. Em outro celular os números serão outros; os passos,
as armadilhas e as verificações valem.

## Dois jeitos de usar

| Você é… | Comece por |
|---|---|
| Uma pessoa seguindo à mão | [`docs/`](docs/), na ordem: `00` → `08` |
| Um agente de IA (Claude Code, Codex, Gemini CLI…) | [`MAPA-AGENTE.md`](MAPA-AGENTE.md) — cada ferramenta tem o seu arquivo de entrada: [`CLAUDE.md`](CLAUDE.md), [`AGENTS.md`](AGENTS.md), [`GEMINI.md`](GEMINI.md) |

## O que funciona e o que não funciona (sem root)

| Funciona | Não funciona |
|---|---|
| SSH (porta 8022), PostgreSQL, Python, Node, Git | **Docker** — exige root e kernel com cgroups/namespaces |
| Debian completo via `proot-distro` (pip com wheels `aarch64`) | Chromium / Playwright / automação de navegador |
| APIs FastAPI/uvicorn, bots, agendadores | Serviços que só existem como imagem Docker |
| Hermes Agent + gateway do Telegram | GPU, modelos de IA locais de verdade |
| Autostart pelo Termux:Boot | Subir **antes** do primeiro desbloqueio após reiniciar |

## A arquitetura em uma figura

```
Android (sem root)
└── Termux (F-Droid) ─────────── sshd :8022 · PostgreSQL 127.0.0.1:5432 · página de status
    ├── Termux:Boot ──────────── ~/.termux/boot/start-server.sh (idempotente, pidfiles)
    └── proot-distro: Debian ─── Python do Debian (wheels aarch64 funcionam)
        ├── app Python (ex.: FastAPI em 127.0.0.1:8010) ─► Postgres do Termux
        └── Hermes Agent + gateway do Telegram
Tailscale (app Android) ──────── acesso do PC ao celular sem abrir porta no roteador
```

Por que o Debian, se o Termux já tem Python? Porque o Python do Termux se
identifica como `android-24-arm64_v8a`, e **quase nenhum pacote do PyPI publica
wheel para essa plataforma**: dos 13 pacotes com código nativo testados, 12 não
tinham. Dentro do Debian, o pip usa os wheels `manylinux aarch64`, que existem
para praticamente tudo. Detalhes em [`docs/05-debian-proot.md`](docs/05-debian-proot.md).

## Números da montagem de referência (Moto G31, 2026-09-27)

| Medida | Valor |
|---|---|
| RAM total / disponível antes de qualquer serviço | 3.717 MB / ~1.600 MB (o Android já usava ~1,3 GB de swap) |
| Disco livre | 81 GB |
| `pip install` de uma API FastAPI no Debian | 69 s, `.venv` de 146 MB, nada compilado |
| `pip install -e .` do Hermes Agent v0.20.4 no Debian | 102 s, `.venv` de 170 MB |
| uvicorn parado (RSS) | ~57 MB |
| Gateway do Hermes (RSS) | ~128 MB |
| Disponível com tudo no ar (sshd, Postgres, API, gateway) | ~1.200 MB |
| Resposta do Hermes a uma pergunta curta (OpenRouter) | 19 s |

## Estrutura

```
docs/            passo a passo para pessoas, de 00 a 08, mais armadilhas
scripts/         start-server.sh (boot), server.py (status), diagnostico.sh
MAPA-AGENTE.md   o roteiro para agentes de IA, com portões de verificação
CLAUDE.md        entrada do Claude Code
AGENTS.md        entrada do Codex (e de outras ferramentas que leem AGENTS.md)
GEMINI.md        entrada do Gemini CLI
```

## Avisos

- **Segurança.** O Postgres do Termux nasce com `trust` no `127.0.0.1`, e
  qualquer app do Android alcança o localhost. Antes de guardar dado pessoal,
  troque para `scram-sha-256` ([`docs/08-seguranca.md`](docs/08-seguranca.md)).
- **Energia.** Celular 24 h na tomada: bateria e temperatura não foram medidas
  (o Android 12 bloqueia `/sys/class/thermal` para apps).
- **Nada aqui exige root, nem apaga o celular.** O único passo com o celular no
  cabo é o ajuste por `adb` do limite de processos, e ele é reversível.

## Licença

MIT — ver [`LICENSE`](LICENSE).

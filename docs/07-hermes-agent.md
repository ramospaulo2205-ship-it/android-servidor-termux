# 07 — Hermes Agent e o bot do Telegram

[Hermes Agent](https://github.com/NousResearch/hermes-agent) (Nous Research) é
um agente de IA de terminal com gateway para Telegram, Discord e outros. Na
referência foi a versão **v0.20.4**.

## Por que no Debian, e não no Termux

O guia oficial para Termux manda adicionar um repositório apt próprio. Na data
da montagem, **esse repositório devolvia 404** (testado do celular e do PC), e
o Python do Termux (3.14.6) estava fora do `requires-python = ">=3.11,<3.14"`.
O guia que vem no repositório do Hermes cita outro caminho, um repositório apt
mantido por terceiros num GitHub pessoal, instalado com `curl | bash`; não foi
usado. No Debian o Hermes instala do Git oficial, com wheels prontos.

## Instalar

Fixe um commit que você sabe que funciona (a `main` do dia pode estar quebrada).
O `git fetch` de um commit específico exige o **hash completo** — o abreviado
dá `couldn't find remote ref`.

```bash
proot-distro login debian -- bash -c '
  mkdir -p /root/hermes-agent && cd /root/hermes-agent &&
  git init -q && git remote add origin https://github.com/NousResearch/hermes-agent.git &&
  git fetch -q --depth 1 origin <HASH-COMPLETO-DE-40-CARACTERES> &&
  git checkout -q FETCH_HEAD &&
  python3 -m venv .venv &&
  .venv/bin/pip install -e . &&
  .venv/bin/hermes --version'
```

Atalho para chamar `hermes` direto do Termux:

```bash
cat > $PREFIX/bin/hermes <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
exec proot-distro login debian -- /root/hermes-agent/.venv/bin/hermes "$@"
EOF
chmod +x $PREFIX/bin/hermes
```

## Configurar (`hermes setup`, interativo)

```bash
ssh -t -p 8022 <usuario>@<ip> hermes setup
```

Escolhas que funcionaram na referência:

| Pergunta | Resposta | Por quê |
|---|---|---|
| Como configurar | **Full setup** | usa a sua própria chave (ex.: OpenRouter); o Quick Setup cria conta no Nous Portal e liga ferramentas por padrão |
| Terminal backend | **Local** | Docker/Singularity exigem root; Modal/Daytona/Vercel são nuvem paga |
| Navegador, voz, Playwright | **não** | não há Chromium no proot |

O que esperar do setup no celular:

- **Ele parece travado, mas está trabalhando.** Primeiro tenta substituir o
  SQLite do Debian (3.46.1, que o Hermes marca como vulnerável ao bug de reset
  do WAL) baixando um Python próprio versão por versão; depois instala
  ferramentas. Em outra sessão SSH, `ps -eo etime,args | grep -E "hermes|uv "`
  mostra o que está rodando.
- **O conserto do SQLite pode falhar sem problema:** o Hermes passa a usar
  `journal_mode=DELETE` em vez de WAL (fica no log como `WARNING`).
- **Cole a chave de API com cuidado.** Na referência a primeira colagem gravou
  254 caracteres com aspas e espaços, e o OpenRouter respondeu
  `HTTP 401: Missing Authentication header`. Para regravar só a chave, sem
  mostrar na tela:

```bash
ssh -t -p 8022 <usuario>@<ip> 'read -rsp "Chave: " K; echo; F=$PREFIX/var/lib/proot-distro/containers/debian/rootfs/root/.hermes/.env; printf "OPENROUTER_API_KEY=%s\n" "$K" > "$F"; chmod 600 "$F"'
```

## Desligar o que não funciona (ou custa)

```bash
hermes tools disable browser computer_use image_gen bfl tts
```

Na referência o setup tinha ligado `image_gen` com um modelo **pago**. Guarde
antes uma cópia do `config.yaml`.

## Testar

```bash
hermes -z "Responda apenas: OK"     # referência: OK em 19 s
```

## Gateway do Telegram

1. Crie um bot no `@BotFather` e ponha no `/root/.hermes/.env` do Debian:
   `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USERS` (e, se quiser,
   `TELEGRAM_HOME_CHANNEL`).
2. **Um bot, um leitor.** O Telegram não aceita duas máquinas lendo o mesmo bot.
   Se o bot já roda em outro lugar (ex.: um serviço `hermes-gateway` no PC),
   pare aquele antes.
3. Suba pelo `start-server.sh` (bloco do Hermes) e confira:

```bash
hermes gateway status                        # "Gateway is running"
grep -E "attempt|Conflict|409" ~/logs/hermes-gateway.log
```

Uma única linha `Connecting to Telegram (attempt 1/8)` sem a segunda é sinal
de conexão feita — o log só registra avisos. A prova final é mandar uma
mensagem ao bot. Na referência o gateway ocupou ~128 MB.

# Instruções para o Claude Code

Este repositório é um guia para montar um servidor num celular Android sem
root. **Siga o [`MAPA-AGENTE.md`](MAPA-AGENTE.md)**, fase por fase, parando em
cada portão. Os detalhes de cada passo estão em [`docs/`](docs/).

Notas específicas do Claude Code:

- Rode os comandos do celular pela ferramenta Bash, via `ssh -o BatchMode=yes
  -p 8022 <usuario>@<ip> '...'`. Use `timeout` nos comandos.
- Instalação de pacotes, `pip install` e `proot-distro install` passam de 2
  minutos: use `run_in_background` e espere a notificação, em vez de laços com
  `sleep`.
- Passos interativos (`passwd`, `hermes setup`, login do Tailscale): entregue o
  comando pronto para a pessoa rodar no terminal dela (ela pode usar o prefixo
  `!` para a saída cair na conversa, exceto nos que pedem senha ou chave).
- Quando a decisão for dela (mover um bot, copiar dados, abrir porta), use a
  ferramenta de pergunta com opções, e ponha a recomendada primeiro.
- Se o modo automático recusar um passo (ex.: repositório apt de terceiro),
  não contorne: explique e peça a decisão à pessoa.
- Não publique nada deste repositório com dados do celular dela (IP, usuário,
  serial, senhas): o registro da montagem fica fora do repositório.

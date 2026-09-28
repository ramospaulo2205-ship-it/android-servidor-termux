# Instruções para o Gemini CLI

Este repositório é um guia para montar um servidor num celular Android sem
root. **Siga o [`MAPA-AGENTE.md`](MAPA-AGENTE.md)**, fase por fase, parando em
cada portão. Os detalhes de cada passo estão em [`docs/`](docs/).

Notas para o Gemini CLI:

- Rode os comandos do celular pelo shell, via `ssh -o BatchMode=yes -p 8022
  <usuario>@<ip> '...'`, sempre com `timeout`.
- Comandos longos no celular levam minutos: rode em segundo plano, gravando em
  `~/logs/`, e confira o log depois.
- Passos interativos (`passwd`, `hermes setup`, login do Tailscale) são da
  pessoa: entregue o comando pronto e espere ela confirmar.
- Mesmo com aprovação automática ligada, pare e pergunte antes das ações da
  lista "Pergunte antes de" do mapa.
- Não grave neste repositório dados do celular da pessoa (IP, usuário, serial,
  senhas): ele é público. O registro da montagem fica fora dele.

# Instruções para agentes (Codex e ferramentas que leem AGENTS.md)

Este repositório é um guia para montar um servidor num celular Android sem
root. **Siga o [`MAPA-AGENTE.md`](MAPA-AGENTE.md)**, fase por fase, parando em
cada portão. Os detalhes de cada passo estão em [`docs/`](docs/).

Notas para o Codex e similares:

- O celular é alcançado por `adb` e por `ssh -o BatchMode=yes -p 8022
  <usuario>@<ip>`. Se o seu sandbox bloquear rede ou `adb`, peça à pessoa para
  liberar o acesso de rede, ou para rodar os comandos e colar a saída.
- Comandos longos no celular (instalar pacotes, `pip install`, `proot-distro
  install`) levam minutos: aumente o tempo limite da execução ou rode em
  segundo plano e confira pelo log (`~/logs/`).
- Passos interativos (`passwd`, `hermes setup`, login do Tailscale) são da
  pessoa: entregue o comando pronto e espere ela confirmar.
- Antes de qualquer ação da lista "Pergunte antes de" do mapa, pare e pergunte,
  mesmo em modo de aprovação automática.
- Não grave neste repositório dados do celular da pessoa (IP, usuário, serial,
  senhas): ele é público. O registro da montagem fica fora dele.

# 04 — Tudo subindo sozinho (Termux:Boot)

O Termux:Boot roda os scripts de `~/.termux/boot/` quando o celular liga
(depois do primeiro desbloqueio — ver [01](01-preparar-android.md)).

```bash
mkdir -p ~/.termux/boot ~/logs
cp scripts/start-server.sh ~/.termux/boot/
chmod +x ~/.termux/boot/start-server.sh
~/.termux/boot/start-server.sh      # rode à mão para testar
tail ~/logs/boot.log
```

## Como o script é feito, e por quê

[`../scripts/start-server.sh`](../scripts/start-server.sh):

- **`termux-wake-lock`** primeiro: impede o Android de suspender o Termux.
- **Idempotente.** Cada serviço só sobe se não estiver vivo. Rodar duas vezes
  não duplica nada; a segunda execução só registra "já rodando".
- **Pidfile conferido pelo `cmdline`.** Depois de um reboot, o pidfile antigo
  sobra e o número pode ter sido reusado por outro processo. A função `vivo`
  só aceita o PID se o processo for mesmo o esperado.
- **Serviços do Debian com o `nohup` do lado de fora.** Ver [05](05-debian-proot.md).
- **Blocos opcionais.** O bloco de um serviço só roda se o arquivo dele existir,
  então o mesmo script serve do servidor mínimo ao completo.

## Parar um serviço

Serviço que roda direto no Termux (página de status, por exemplo):

```bash
kill $(cat ~/logs/<servico>.pid)
```

Serviço que roda no Debian: o pidfile guarda o PID do `proot`, e **o `proot`
ignora o `SIGTERM`** (medido na referência: o gateway do Hermes seguiu vivo).
Mande o sinal para o processo filho; ele encerra e o `proot` sai junto
(na referência, em 5 s):

```bash
P=$(cat ~/logs/<servico>.pid)
kill $(ps -eo pid,ppid | awk -v p=$P '$2==p{print $1}')
while kill -0 $P 2>/dev/null; do sleep 1; done     # espera o proot sair
```

**Nunca use `pkill -f <trecho>` numa sessão SSH.** O padrão casa com a linha de
comando da própria sessão (que contém o trecho) e derruba a sua conexão — isso
aconteceu duas vezes na montagem de referência. Use o pidfile.

## Testar o boot de verdade

```bash
adb reboot     # ou reinicie pelo botão
# desbloqueie o celular e espere ~2 minutos
ssh -p 8022 <usuario>@<ip> 'tail ~/logs/boot.log'
```

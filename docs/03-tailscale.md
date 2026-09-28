# 03 — Acesso remoto pelo Tailscale

O Tailscale cria uma rede privada entre o PC e o celular, sem abrir porta no
roteador e sem IP público — funciona inclusive atrás de CGNAT e de roteador com
painel bloqueado.

1. Instale o app **Tailscale** no celular e entre na sua conta.
2. Instale o Tailscale no PC e entre na **mesma** conta.
3. O app do celular mostra o IP dele (faixa `100.x.y.z`).

Teste do PC:

```bash
ssh -p 8022 <usuario>@<ip-tailscale-do-celular>
curl -s -m 5 http://<ip-tailscale-do-celular>:5432 ; echo "exit=$?"   # tem de FALHAR (Postgres só local)
```

Na referência, 8022 respondia e 5432 era recusada pelo IP do Tailscale.

Prefira o Tailscale ao `adb forward`: o túnel do adb morre quando o servidor
adb do PC cai.

## Serviço só local, acesso só por túnel

Para um serviço que não deve ficar exposto nem na rede do Tailscale (API sem
login, dado pessoal), suba em `127.0.0.1` no celular e acesse do PC por túnel:

```bash
ssh -p 8022 -L 8010:127.0.0.1:8010 -N <usuario>@<ip-tailscale-do-celular>
# em outro terminal do PC:
curl http://127.0.0.1:8010/
```

## Publicar na internet

Se algo precisar ser público, o `cloudflared` (Cloudflare Tunnel) existe no
repositório do Termux (`pkg install cloudflared`). Não foi usado na referência.

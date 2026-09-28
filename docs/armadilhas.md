# Armadilhas (todas aconteceram na montagem de referência)

| Sintoma | Causa | Saída |
|---|---|---|
| `curl`: `cannot locate symbol "SSL_set_quic_tls_early_data_enabled"` | `pkg install` avulso atualizou `libcurl` e não o `openssl` | `apt-get -s full-upgrade` e depois `full-upgrade --force-confold` |
| `gpg: libgcrypt is too old` | mesma causa | idem |
| `pip download` "encontra" `pydantic-core` no Termux | é o placeholder `0.0.1`, vazio | conferir a versão baixada; usar o Debian |
| Pacote Python sem wheel no Termux | plataforma `android-24-arm64_v8a` | Debian via `proot-distro` |
| Arquivos copiados para o Debian não aparecem lá dentro | copiados para `installed-rootfs/`; o rootfs real é `containers/debian/rootfs/` | criar um arquivo-marca dentro e achar com `find` |
| Serviço do Debian morre quando o SSH fecha | `nohup` dentro do `proot-distro login`, que tem `--kill-on-exit` | `nohup proot-distro login ... &` do lado de fora |
| Conexão SSH cai com código 255 ao parar um serviço | `pkill -f` casou com a linha de comando da própria sessão | pidfile + `kill $(cat arquivo.pid)` |
| `kill` no PID do serviço do Debian e ele continua no ar | o PID do pidfile é do `proot`, que ignora `SIGTERM` | matar o processo filho do `proot` ([04](04-autostart.md)) |
| Rota da API dá 500 com `FileNotFoundError` em `site-packages` | instalado sem `-e`; o código lê arquivo por caminho relativo | `pip install -e .` |
| `git fetch origin <hash>` → `couldn't find remote ref` | hash abreviado | usar os 40 caracteres |
| Repositório apt do guia oficial do Hermes dá 404 | publicado no guia antes de existir | instalar pelo Git no Debian |
| Hermes: `HTTP 401: Missing Authentication header` | chave colada com lixo junto | regravar com `read -rsp` e conferir comprimento/prefixo |
| `hermes setup` "travado" | baixando Python próprio para trocar o SQLite; instalando ferramentas | acompanhar com `ps` em outra sessão; esperar |
| Nada sobe depois de reiniciar | autostart só roda após o primeiro desbloqueio | desbloquear; ver [01](01-preparar-android.md) §4 |
| Load average ~21 com o celular parado | contagem do Android, não carga real | ignorar; `/proc/stat` é bloqueado |
| `/proc/uptime`, `/sys/class/thermal`, `/proc/net/tcp` ilegíveis | bloqueio do Android 12 para apps | `CLOCK_BOOTTIME`; `adb shell ss -ltn` |
| Celular não aparece no `lsusb` | cabo, porta ou modo USB | trocar cabo; modo "transferência de arquivos" |

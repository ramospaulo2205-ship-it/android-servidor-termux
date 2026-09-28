# 01 — Preparar o Android

## 1. Opções de desenvolvedor e depuração USB

Configurações → Sobre o telefone → toque 7 vezes em "Número da versão".
Depois, em Opções do desenvolvedor, ligue **Depuração USB**.

No PC:

```bash
adb devices          # tem de aparecer como "device", não "unauthorized"
```

Se o celular nem aparece no `lsusb`, o problema costuma ser **cabo, porta ou
modo USB** (só carga), não o adb nem o udev. Foi o caso na referência.

## 2. Limite de processos em segundo plano (Android 12 ou mais novo)

O Android 12 mata processos-filho de apps acima de 32 ("phantom processes").
Um servidor com sshd, Postgres, proot e Python passa disso fácil. Pelo `adb`:

```bash
adb shell device_config set_sync_disabled_for_tests persistent
adb shell device_config put activity_manager max_phantom_processes 2147483647
adb shell device_config get activity_manager max_phantom_processes   # confere
```

Na referência o valor sobreviveu ao reboot (conferido depois de um `adb reboot`).
Para desfazer: `adb shell device_config set_sync_disabled_for_tests none`.

## 3. Bateria sem restrição

Para **Termux** e **Termux:Boot**: Configurações → Apps → (app) → Bateria →
**Sem restrições**. Sem isso o Android suspende o servidor com a tela apagada.

## 4. Tela de bloqueio

O autostart só roda **depois do primeiro desbloqueio** após ligar o celular
(medido na referência: ligado 12:54, desbloqueado 13:13:07, script 13:14:26).
É efeito da criptografia por arquivo do Android: antes do desbloqueio o
armazenamento dos apps está fechado. Decida agora uma das saídas:

- aceitar o risco e desbloquear depois de toda queda de energia;
- tirar o bloqueio de tela (menos seguro);
- adiar atualizações automáticas do sistema, que reiniciam de madrugada.

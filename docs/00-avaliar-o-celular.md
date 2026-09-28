# 00 — Avaliar o celular antes de começar

Meia hora aqui evita dias de trabalho num aparelho que não aguenta. O script
[`../scripts/diagnostico.sh`](../scripts/diagnostico.sh) faz as medições
abaixo de uma vez; esta página explica como ler.

## Requisitos mínimos

| Item | Mínimo prático | Por quê |
|---|---|---|
| Arquitetura | `aarch64` (arm64) | é para ela que existem os wheels `manylinux aarch64` usados no Debian |
| RAM | 3 GB; 4 GB é mais confortável | o próprio Android ocupa metade; na referência sobravam ~1,6 GB |
| Disco livre | 10 GB | Debian + dois ambientes Python + Postgres passam de 1 GB |
| Android | o Termux do F-Droid pede Android 7 ou mais novo | — |

## O que medir (e como a referência respondeu)

```bash
uname -m                                  # aarch64
getprop ro.product.model                  # moto g31
getprop ro.build.version.release          # 12
getprop ro.board.platform                 # mt6768
free -m                                   # total 3717, available ~1600
df -h $HOME                               # 81G livres
python -c "import sysconfig; print(sysconfig.get_platform())"   # android-24-arm64_v8a
```

## Duas leituras que enganam

- **Load average alto não prova carga.** A referência marcava ~21 parada: o
  Android conta threads que não estão usando CPU. E `/proc/stat` devolve
  `Permission denied` para apps, então o uso real de CPU não é mensurável de
  dentro do Termux.
- **Swap já em uso antes de começar é normal no Android** (a referência tinha
  1,26 GB). Olhe a coluna `available` do `free -m`, não a `free`.

## Teste de compatibilidade dos pacotes Python

Rode no Termux, para os pacotes nativos do seu projeto:

```bash
d=$(mktemp -d); cd $d
for p in asyncpg pydantic-core psycopg-binary cryptography pyyaml; do
  python -m pip download -q --no-deps --only-binary=:all: -d . $p >/dev/null 2>&1 \
    && echo "$p TEM wheel Android" || echo "$p SEM wheel"
done
ls; cd; rm -rf $d
```

Na referência, 12 de 13 deram **SEM wheel**. O único que "passou",
`pydantic-core`, baixou `pydantic_core-0.0.1-py3-none-any.whl`, um pacote
vazio que só ocupa o nome. **Confira a versão do que baixou**, não só o código
de saída. Com esse resultado, o caminho é o Debian no proot
([05](05-debian-proot.md)).

## Instalar Ubuntu no lugar do Android?

Foi avaliado e descartado para a referência:

- Não havia port do Ubuntu Touch nem do postmarketOS para o aparelho (codinome
  `coful`), e desbloquear o bootloader **apaga o celular**.
- Docker exigiria root, que também passa pelo desbloqueio.

Confira o codinome e o estado do bootloader do seu:

```bash
getprop ro.product.device           # codinome, para procurar port
getprop ro.boot.flash.locked        # 1 = travado
getprop sys.oem_unlock_allowed      # 0 = desbloqueio desligado nas opções de desenvolvedor
```

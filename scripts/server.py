#!/data/data/com.termux/files/usr/bin/python
"""Página de status de um servidor Termux.

Só biblioteca padrão. GET / devolve JSON com hostname, uptime, memória,
disco, temperatura e se o Postgres responde.

Escuta em STATUS_HOST:STATUS_PORT (padrão 127.0.0.1:8080). Use o IP do
Tailscale para ver do PC; 0.0.0.0 expõe a página para toda a Wi-Fi.
"""
import glob
import json
import os
import shutil
import socket
import subprocess
import time
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HOST = os.environ.get("STATUS_HOST", "127.0.0.1")
PORT = int(os.environ.get("STATUS_PORT", "8080"))


def ler(caminho: str) -> str | None:
    try:
        with open(caminho) as f:
            return f.read().strip()
    except OSError:
        return None


def uptime() -> dict:
    # /proc/uptime é bloqueado para apps no Android 12; CLOCK_BOOTTIME é o
    # mesmo relógio (conta o tempo em suspensão) e vem por syscall.
    seg = time.clock_gettime(time.CLOCK_BOOTTIME)
    d, resto = divmod(int(seg), 86400)
    h, resto = divmod(resto, 3600)
    m, _ = divmod(resto, 60)
    return {"segundos": round(seg), "legivel": f"{d}d {h}h {m}m"}


def memoria() -> dict:
    bruto = ler("/proc/meminfo")
    if bruto is None:
        return {"erro": "/proc/meminfo ilegível"}
    campos = {}
    for linha in bruto.splitlines():
        chave, _, valor = linha.partition(":")
        partes = valor.split()
        if partes and partes[0].isdigit():
            campos[chave] = int(partes[0])  # kB
    quero = ("MemTotal", "MemAvailable", "MemFree", "SwapTotal", "SwapFree")
    return {f"{k}_mb": round(campos[k] / 1024) for k in quero if k in campos}


def disco() -> dict:
    home = os.path.expanduser("~")
    u = shutil.disk_usage(home)
    gb = 1024 ** 3
    return {
        "caminho": home,
        "total_gb": round(u.total / gb, 1),
        "usado_gb": round(u.used / gb, 1),
        "livre_gb": round(u.free / gb, 1),
        "uso_pct": round(u.used / u.total * 100, 1),
    }


def temperatura() -> dict:
    zonas = {}
    for zona in sorted(glob.glob("/sys/class/thermal/thermal_zone*")):
        valor = ler(os.path.join(zona, "temp"))
        if valor is None or not valor.lstrip("-").isdigit():
            continue
        tipo = ler(os.path.join(zona, "type")) or os.path.basename(zona)
        n = int(valor)
        zonas[tipo] = n / 1000 if abs(n) > 1000 else n  # miligraus → °C
    return {"legivel": bool(zonas), "zonas_c": zonas}


def postgres() -> dict:
    try:
        r = subprocess.run(
            ["pg_isready", "-h", "localhost"],
            capture_output=True, text=True, timeout=5,
        )
        return {"responde": r.returncode == 0, "saida": r.stdout.strip()}
    except (OSError, subprocess.TimeoutExpired) as e:
        return {"responde": False, "saida": str(e)}


def status() -> dict:
    return {
        "hostname": socket.gethostname(),
        "agora": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "uptime": uptime(),
        "memoria": memoria(),
        "disco": disco(),
        "temperatura": temperatura(),
        "postgres": postgres(),
    }


class Handler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path != "/":
            self.send_error(404)
            return
        corpo = json.dumps(status(), ensure_ascii=False, indent=2).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(corpo)))
        self.end_headers()
        self.wfile.write(corpo)


if __name__ == "__main__":
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()

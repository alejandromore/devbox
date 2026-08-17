#!/usr/bin/env python3
"""Alta inicial del devbox.

Corre solo hasta que definis la contrasena del escritorio. Cuando la recibe:
la guarda en el .kasmpasswd del ECS, arranca KasmVNC, reapunta Caddy al
escritorio y se deshabilita sola.

La contrasena no pasa por Jenkins, no queda en el repo y no viaja por la linea
de comandos: se escribe por stdin a kasmvncpasswd.

Escucha solo en loopback; quien la expone con TLS es Caddy.
"""

import http.server
import os
import pathlib
import shutil
import socket
import subprocess
import threading
import time
import urllib.parse

DEVBOX_USER = os.environ.get("DEVBOX_USER", "devbox")
LISTEN_HOST = "127.0.0.1"
LISTEN_PORT = 6902
MIN_LEN = 12

MARKER = pathlib.Path("/var/lib/devbox/.password-set")
UPSTREAM_CONF = pathlib.Path("/etc/caddy/devbox-upstream.conf")
KASM_PASSWD = pathlib.Path(f"/home/{DEVBOX_USER}/.kasmpasswd")

DESKTOP_UPSTREAM = """# Gestionado por devbox-setup: el escritorio ya tiene contrasena.
reverse_proxy 127.0.0.1:6901 {
    header_up X-Real-IP {remote_host}
    transport http {
        read_timeout 0
        write_timeout 0
    }
}
"""

STYLE = """
  :root { color-scheme: light dark; }
  body { margin:0; min-height:100vh; display:flex; align-items:center;
         justify-content:center; font-family: system-ui, sans-serif;
         background:#f4f4f5; color:#18181b; }
  @media (prefers-color-scheme: dark) {
    body { background:#18181b; color:#f4f4f5; }
    .card { background:#27272a !important; border-color:#3f3f46 !important; }
    input { background:#18181b !important; color:#f4f4f5 !important;
            border-color:#52525b !important; }
  }
  .card { background:#fff; border:1px solid #e4e4e7; border-radius:12px;
          padding:2rem; width:min(26rem, 92vw); }
  h1 { font-size:1.25rem; margin:0 0 .25rem; }
  p.sub { margin:0 0 1.5rem; opacity:.7; font-size:.9rem; }
  label { display:block; font-size:.85rem; margin-bottom:.35rem; }
  input { width:100%; box-sizing:border-box; padding:.6rem .7rem;
          border:1px solid #d4d4d8; border-radius:8px; font-size:1rem;
          margin-bottom:1rem; }
  button { width:100%; padding:.7rem; border:0; border-radius:8px;
           background:#2563eb; color:#fff; font-size:1rem; cursor:pointer; }
  button:hover { background:#1d4ed8; }
  .err { background:#fee2e2; color:#991b1b; padding:.6rem .7rem;
         border-radius:8px; font-size:.85rem; margin-bottom:1rem; }
"""

FORM = """<!doctype html>
<html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>devbox - alta inicial</title><style>{style}</style></head>
<body><div class="card">
  <h1>Configurar el escritorio</h1>
  <p class="sub">Defini la contrasena con la que vas a entrar. Se guarda en el
  servidor; esta pantalla no vuelve a aparecer.</p>
  {error}
  <form method="POST" action="/">
    <label for="p1">Contrasena (minimo {minlen} caracteres)</label>
    <input id="p1" name="password" type="password" autocomplete="new-password"
           required minlength="{minlen}" autofocus>
    <label for="p2">Repetila</label>
    <input id="p2" name="confirm" type="password" autocomplete="new-password"
           required minlength="{minlen}">
    <button type="submit">Guardar y entrar</button>
  </form>
</div></body></html>
"""

DONE = """<!doctype html>
<html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>devbox - listo</title><meta http-equiv="refresh" content="8">
<style>{style}</style></head>
<body><div class="card">
  <h1>Listo</h1>
  <p class="sub">El escritorio esta arrancando. Esta pagina se recarga sola en
  unos segundos y te va a pedir usuario <b>{user}</b> con la contrasena que
  acabas de definir.</p>
</div></body></html>
"""


def already_configured():
    return MARKER.exists()


def run(cmd, **kwargs):
    return subprocess.run(cmd, check=True, capture_output=True, text=True, **kwargs)


def wait_for_desktop(timeout=90):
    """Espera a que KasmVNC acepte conexiones en 6901."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        with socket.socket() as probe:
            probe.settimeout(2)
            if probe.connect_ex(("127.0.0.1", 6901)) == 0:
                return True
        time.sleep(2)
    return False


def set_password(password):
    """Guarda la contrasena y deja el escritorio servido por Caddy.

    Caddy se reapunta al escritorio recien cuando KasmVNC contesta: si se
    reapunta antes y la sesion no levanta, la pagina de alta queda inalcanzable
    y el sitio responde 502 sin forma de reintentar desde el navegador.
    """
    run(
        [
            "runuser", "-u", DEVBOX_USER, "--",
            "kasmvncpasswd", "-u", DEVBOX_USER, "-w", "-o", str(KASM_PASSWD),
        ],
        input=f"{password}\n{password}\n",
        env={**os.environ, "HOME": f"/home/{DEVBOX_USER}"},
    )
    shutil.chown(KASM_PASSWD, user=DEVBOX_USER, group=DEVBOX_USER)
    KASM_PASSWD.chmod(0o600)

    run(["systemctl", "enable", "--now", "kasmvnc"])

    if not wait_for_desktop():
        raise RuntimeError(
            "KasmVNC no llego a escuchar en 6901. Revisa "
            "'journalctl -u kasmvnc' en el ECS. La contrasena quedo guardada; "
            "esta pagina sigue disponible para reintentar."
        )

    MARKER.parent.mkdir(parents=True, exist_ok=True)
    MARKER.touch()

    UPSTREAM_CONF.write_text(DESKTOP_UPSTREAM)
    run(["systemctl", "reload", "caddy"])


def shutdown_self():
    # Se apaga despues de contestar: systemd corta el servicio y no vuelve a
    # levantarlo en el proximo arranque.
    subprocess.Popen(["systemctl", "disable", "--now", "devbox-setup.service"])


class Handler(http.server.BaseHTTPRequestHandler):
    server_version = "devbox-setup"

    def _send(self, body, status=200):
        raw = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(raw)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(raw)

    def _form(self, error="", status=200):
        block = f'<div class="err">{error}</div>' if error else ""
        self._send(
            FORM.format(style=STYLE, error=block, minlen=MIN_LEN), status
        )

    def do_GET(self):
        if already_configured():
            self._send(DONE.format(style=STYLE, user=DEVBOX_USER))
            return
        self._form()

    def do_POST(self):
        length = int(self.headers.get("Content-Length") or 0)
        if length <= 0 or length > 4096:
            self._form("Peticion invalida.", 400)
            return

        # Hay que drenar el cuerpo siempre, incluso si vamos a descartarlo:
        # contestar sin leerlo le corta la conexion al navegador.
        body = self.rfile.read(length)

        if already_configured():
            self._send(DONE.format(style=STYLE, user=DEVBOX_USER))
            return

        fields = urllib.parse.parse_qs(body.decode("utf-8"))
        password = (fields.get("password") or [""])[0]
        confirm = (fields.get("confirm") or [""])[0]

        if len(password) < MIN_LEN:
            self._form(f"Muy corta: minimo {MIN_LEN} caracteres.", 400)
            return
        if password != confirm:
            self._form("Las dos contrasenas no coinciden.", 400)
            return

        try:
            set_password(password)
        except subprocess.CalledProcessError as exc:
            self._form(f"No se pudo aplicar: {exc.stderr or exc}".strip(), 500)
            return
        except RuntimeError as exc:
            self._form(str(exc), 500)
            return

        self._send(DONE.format(style=STYLE, user=DEVBOX_USER))
        threading.Timer(2.0, shutdown_self).start()

    def log_message(self, fmt, *args):
        # Al journal, nunca el cuerpo del POST.
        print(f"devbox-setup: {self.address_string()} {fmt % args}", flush=True)


def main():
    server = http.server.ThreadingHTTPServer((LISTEN_HOST, LISTEN_PORT), Handler)
    print(f"devbox-setup escuchando en {LISTEN_HOST}:{LISTEN_PORT}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()

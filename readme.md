# devbox

Escritorio Linux remoto en Huawei Cloud, accesible por navegador.
XFCE + KasmVNC detrás de Caddy con TLS de Let's Encrypt.

- Dominio: `devbox.alejandromore.lat`
- ECS: `ecs-devbox`, 4 vCPU / 8 GB, Ubuntu 24.04, 1 disco SSD de 100 GB
- Red: `vpc-devbox` (10.4.0.0/16), `subnet-devbox` (10.4.32.0/19), `sg-devbox` (22, 80, 443)
- Región: `la-south-2`

## Estructura

```
terraform/    VPC + ECS + EIP (backend S3 sobre OBS, key devbox.tfstate)
ansible/      playbook del escritorio y las herramientas
Jenkinsfile   pipeline de 2 etapas: Terraform y Ansible
```

## Orden de ejecución

El orden importa: **Let's Encrypt no emite el certificado si el dominio todavía
no resuelve a la IP**, así que el paso 4 no se puede saltar ni adelantar.

1. **Credencial en Jenkins** — crear `devbox-web-pass` (secret text) con la
   contraseña de acceso web. Las otras (`hwc-access-key`, `hwc-secret-key`,
   `github-creds`) ya existen.
2. **Job del pipeline** — apuntarlo a este repo, rama `main`.
3. **Build #1** — `ACTION=deploy`, `RUN_TERRAFORM=true`, `RUN_ANSIBLE=false`.
   Jenkins imprime la IP pública del ECS.
4. **DNS** — registrar en Namecheap el A record `devbox` → esa IP. Esperar a que
   resuelva (`nslookup devbox.alejandromore.lat`).
5. **Build #2** — `ACTION=deploy`, `RUN_TERRAFORM=false`, `RUN_ANSIBLE=true`,
   `ECS_PUBLIC_IP=<la IP del paso 3>`.

## Cómo entrar

Navegador → `https://devbox.alejandromore.lat`
Usuario `devbox`, contraseña la que cargaste en `devbox-web-pass`.

KasmVNC escucha solo en `127.0.0.1:6901`; lo único expuesto a Internet es Caddy.
La sesión es persistente (systemd `kasmvnc.service`): cerrar la pestaña no mata
lo que estabas haciendo.

Acceso por SSH: usuario `root` (o `devbox`) con la llave privada
`basic-project-private-key`, que sale de CSMS vía el output `ecs_private_key`.

## Herramientas instaladas

| Grupo | Qué va |
|---|---|
| Escritorio | XFCE, KasmVNC, Caddy, fail2ban |
| Editor / navegador | Visual Studio Code, Google Chrome |
| IA | Claude Code CLI, goose, Antigravity ⚠️ |
| IaC / K8s | Terraform, kubectl, Helm, Ansible |
| Cloud | hcloud (KooCLI) |
| Contenedores | Podman |
| Lenguajes | Node.js LTS + npm, Python 3 + pip + venv |
| Base | git, curl, jq, unzip |

⚠️ Antigravity es una tarea tolerante a fallo: si la descarga no resuelve, el
playbook avisa en el log y sigue. Se instala a mano desde el Chrome del escritorio.

Para agregar una herramienta, editar `ansible/playbook/vars/tools.yml`. No hace
falta tocar el playbook.

## Cómo destruir el ambiente

Pipeline: `ACTION=destroy`, `RUN_TERRAFORM=true`, `RUN_ANSIBLE=false`.

A mano, desde `terraform/`:

```bash
terraform destroy -var-file="local.tfvars" -auto-approve
```

Después conviene borrar el A record en Namecheap.

## Terraform local (para probar sin Jenkins)

```bash
terraform init
terraform validate
terraform plan -var-file="local.tfvars" -out=tfplan
terraform apply tfplan
```

Requiere `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` (backend OBS) y
`HW_ACCESS_KEY` / `HW_SECRET_KEY` (provider) en el entorno.

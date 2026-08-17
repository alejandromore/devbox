# devbox

Escritorio Linux remoto en Huawei Cloud, accesible por navegador.
XFCE + KasmVNC detrás de Caddy con TLS de Let's Encrypt.

- Dominio: `devbox.alejandromore.lat`
- ECS: `ecs-devbox`, 4 vCPU / 8 GB, Ubuntu 24.04, 1 disco SSD de 100 GB
- Red: `vpc-devbox` (10.4.0.0/16), `subnet-devbox` (10.4.32.0/19), `sg-devbox` (22, 80, 443)
- Región: `la-south-2`

## Estructura

```
terraform/
  00-main.tf            data sources (EP, AZs, flavor por CPU+RAM)
  locals.tf             naming estandar a partir de app_env
  01-network.tf         VPC + subnet
  02-security_groups.tf SG + reglas 22, 80, 443 y egress
  03-components.tf      EIP (5_bgp, PER) + asociacion al ECS
  04-compute.tf         keypair + secreto en CSMS + ECS
  backend.tf            state en OBS: obs-terraform-tfstate/devbox.tfstate
ansible/                playbook del escritorio y las herramientas
Jenkinsfile             pipeline de 2 etapas: Terraform y Ansible
```

Sin módulos: todo son recursos básicos del provider, con la misma estructura
que `tdp-jenkins-ecs`.

## Orden de ejecución

El orden importa: **Let's Encrypt no emite el certificado si el dominio todavía
no resuelve a la IP**, así que el paso 3 no se puede saltar ni adelantar.

1. **Job del pipeline** — `devbox` en `https://110.238.64.8`, apuntando a este
   repo, rama `main`, corriendo sobre el agente `agent-huawei`. Usa las
   credenciales que ya existen (`hwc-access-key`, `hwc-secret-key`,
   `github-creds`); no hace falta ninguna nueva.
2. **Build #1** — `ACTION=deploy`, `RUN_TERRAFORM=true`, `RUN_ANSIBLE=false`.
   Jenkins imprime la IP pública del ECS.
3. **DNS** — registrar en Namecheap el A record `devbox` → esa IP. Esperar a que
   resuelva (`nslookup devbox.alejandromore.lat`).
4. **Build #2** — `ACTION=deploy`, `RUN_TERRAFORM=false`, `RUN_ANSIBLE=true`,
   `ECS_PUBLIC_IP=<la IP del paso 2>`.
5. **Alta** — entrar a `https://devbox.alejandromore.lat` y definir ahí la
   contraseña del escritorio.

## Cómo entrar

Navegador → `https://devbox.alejandromore.lat`, usuario `devbox`.

La contraseña no vive en Jenkins ni en este repo: la definís vos la primera vez
que entrás. Al terminar el build #2 Caddy no apunta al escritorio sino a una
página de alta (`devbox-setup`, en `127.0.0.1:6902`). Cuando cargás la
contraseña ahí, el servicio la guarda en el `.kasmpasswd` del ECS, arranca
KasmVNC, reapunta Caddy al escritorio y se deshabilita solo. De ahí en adelante
esa URL es el escritorio.

⚠️ Hacé el alta apenas termina el build: hasta que definas la contraseña, esa
página está abierta a cualquiera que llegue al dominio. Si te preocupa la
ventana, dejá `allowed_https_cidr` en tu IP durante el deploy y abrilo después.

Para rehacer el alta: borrar `/var/lib/devbox/.password-set` en el ECS, restaurar
`/etc/caddy/devbox-upstream.conf` al puerto 6902 y volver a correr el playbook.

KasmVNC escucha solo en `127.0.0.1:6901`; lo único expuesto a Internet es Caddy.
La sesión es persistente (systemd `kasmvnc.service`): cerrar la pestaña no mata
lo que estabas haciendo.

Acceso por SSH: usuario `root` (o `devbox`) con la llave privada del secreto
`csms-devbox-private-key`, que sale de CSMS vía el output `ecs_private_key`.

Terraform crea el par de llaves de cero: `kp-devbox` en KPS y la privada guardada
en CSMS como `csms-devbox-private-key`. No se reusa ninguna llave existente.

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

Un detalle de la API de VPC: rechaza una regla de security group si la
descripción trae `>` (responde `is invalid rule!`). Por eso las descripciones
en `02-security_groups.tf` son texto plano, sin flechas.

Requiere `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` (backend OBS) y
`HW_ACCESS_KEY` / `HW_SECRET_KEY` (provider) en el entorno.

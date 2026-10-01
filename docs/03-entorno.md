# ¿Dónde se validó el proyecto?

## TL;DR

La máquina física principal es Fedora 44 KDE (i3-1220P, 16 GiB RAM, KVM). Además la suite corre en una **matriz multi-distro** (contenedores, CI y validación local): CachyOS, Arch, Fedora, Debian y Ubuntu. Las suites usan tar.gz falsos en `/tmp`, así que no dependen de la máquina.

## Matriz multi-distro (2026-10-01)

| Distro | Familia | bash | Cómo se validó | Resultado |
|---|---|---|---|---|
| Fedora 44 | Fedora | 5.3.9 | máquina física + contenedor + CI | **111/111 PASS** |
| CachyOS | Arch | 5.3.20 | contenedor `cachyos/cachyos` + CI | **111/111 PASS** |
| Arch Linux | Arch | 5.3.20 | contenedor `archlinux` + CI | **111/111 PASS** |
| Ubuntu | Debian | 5.x | CI (`ubuntu-latest`) | **111/111 PASS** |
| Debian stable | Debian | 5.x | contenedor `debian:stable-slim` + CI | **111/111 PASS** |

La suite no requiere `git`: la aserción de secretos usa `grep -r` nativo (excluye `.git` y `tests/`), así que las 5 distros corren las mismas 111 sin instalar nada.

El invariante que garantiza la portabilidad está en `whitebox_content.test.sh`: el código ejecutable (`setup.sh`, `uninstall.sh`, `src/`) **no referencia ningún gestor de paquetes** (`dnf`, `apt-get`, `pacman`, `zypper`, `rpm`, `emerge`, `flatpak`). Únicas dependencias: `bash 5.x`, `tar`, `curl` o `wget`, `flock`, `sha256sum`.

## Equipo donde se validó (specs reales)

| Componente | Valor |
|---|---|
| Sistema operativo | Fedora Linux 44 (KDE Plasma Desktop Edition) |
| Arquitectura | x86_64 |
| Kernel | 7.2.7-200.fc44.x86_64 |
| CPU | 12th Gen Intel Core i3-1220P (12 hilos) |
| RAM | 16 GiB total (aprox. 10 GiB disponibles en idle) |
| Swap | 8 GiB |
| Disco | NVMe 475 GB partición `/` (376 GB disponibles, 21% usado) |
| Virtualización | baremetal (`systemd-detect-virt` = none), KVM OK (`/dev/kvm` presente) |
| Shell | GNU bash 5.3.9(1)-release |

## Qué implica para el proyecto

- Android Studio Quail 4 Patch 1 (2026.1.4) se ejecutó aquí con el lanzador portable y **no** se validaron builds con el emulador (el SDK sí incluye emulador con KVM disponible).
- Las suites de prueba (`tests/run-tests.sh`) no tocan esta configuración: crean `HOME` y destinos falsos bajo `/tmp` y un tar.gz mínimo, por lo que corren igual en otra máquina.
- Requisito mínimo razonable por extrapolación: 8 GiB RAM recomendados por Android Studio, disco con ~6 GB libres (IDE + SDK). No verificado en hardware menor.

> Over to you: ¿lo probaste en otra distro, versión de bash o hardware? Anotá el resultado en este documento y corré `bash tests/run-tests.sh` para validar que la base sigue verde.
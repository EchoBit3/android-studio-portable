# Entorno de validación

## TL;DR

Todo se probó en una sola máquina física: Fedora 44 KDE, i3-1220P (12 hilos), 16 GiB RAM, NVMe 475 GB, KVM habilitado. Las suites del repo corren en `/tmp` con tar.gz falsos, así que no dependen de esta máquina.

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
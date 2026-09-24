# ¿Qué es Android Studio Portable y por qué te conviene?

> Para usuarios no técnicos. Si querés ver solo "cómo instalo", andá a la sección *Instalar* del README.

## TL;DR

Android Studio es el programa oficial de Google para **crear aplicaciones de Android**. Este proyecto te lo da **dentro de una sola carpeta** en tu PC: lo que usás, lo que guardás y lo que descarga viven juntos. Si querés deshacerte de él, borrás la carpeta. Nada queda instalado en el resto de tu sistema.

## ¿Qué es Android Studio?

Es el **Integrated Development Environment (IDE)** —o "taller de programación"— con el que Google te permite construir apps para teléfonos, tablets, relojes y televisores Android. Incluye:

- Un **editor de código** con inteligencia para el lenguaje Kotlin, Java y la interfaz de las apps.
- Un **sistema de compilación** (Gradle) que convierte tu código en un archivo instalable (`.apk` / `.aab`).
- Un **emulador**: un teléfono virtual que corre en tu PC para probar la app sin tener un celular a mano.
- Un **SDK** (Software Development Kit): la caja de herramientas de Android (bibliotecas, compiladores, emulador, herramientas de depuración).

Normalmente, Android Studio instala estas piezas en **diferentes carpetas de tu computadora** (configuración en tu carpeta de usuario, SDK en `~/Android/Sdk`, cachés en otras), y cuando la instalás, se pegan al disco y son difíciles de mover o limpiar.

## ¿Qué hace diferente a este proyecto?

**Concentra todo en una carpeta.** Después de instalar con este repo, tu carpeta por ejemplo `~/AndroidStudio-Portable` contiene:

- el programa Android Studio,
- el SDK de Android,
- tus emuladores (AVDs),
- la caché de Gradle y las configuraciones,
- temporales.

### Ventajas prácticas

| Si querés... | Con Android Studio Portable |
|---|---|
| Tener dos versiones de Android Studio a la vez (una estable, otra beta) | Creás dos carpetas con `--dest` distinto |
| Llevarlo a otro PC o disco externo | Copiás la carpeta entera |
| Limpiar a fondo | Borra la carpeta (y con `uninstall.sh`, se retira ordenadamente) |
| No instalar nada del sistema | No requiere `sudo` ni instaladores del sistema |

### Lo único que queda "fuera" de la carpeta

Un **symlink**: un acceso directo en `~/Android/Sdk` que apunta a `dentro-de-tu-carpeta/sdk`. Existe porque algunos componentes de Android **solo** buscan el SDK ahí (es un requisito del ecosistema, no una decisión de este proyecto). Este acceso directo pesa 0 bytes, no copia nada, y `uninstall.sh` lo retira automáticamente.

> Nota de seguridad/privacidad: el symlink apunta a **tu carpeta portable**, no a datos personales. No se comparte con nadie; vive solo en tu máquina.

## ¿Cómo instalo?

Andá al README y seguí la sección *Instalar*. En resumen: clonás el repo, corrés un comando (`./setup.sh --dest "$HOME/AndroidStudio-Portable"`), esperás a que descargue (~1.5 GB) y abrís el lanzador `studio-portable.sh` que queda dentro de esa carpeta.

## ¿Preguntas frecuentes?

**¿Es gratis?** Sí, es un proyecto open-source con licencia MIT. Android Studio es gratuito de Google.

**¿Descarga de dónde?** Del sitio oficial de Google (`developer.android.com` y los servidores de descarga de Google). Este repo **no incluye binarios**: los scripts bajan el tar.gz oficial en el momento de instalar.

**¿Toca mis archivos personales?** No. Todo lo que escribe va a la carpeta que elegís con `--dest`, más el symlink `~/Android/Sdk` descrito arriba. No hay recolección de datos ni telemetría propia (ver `06-privacidad.md`).

**¿Y si algo falla al instalar?** Corré `bash tests/run-tests.sh` en el repo: son pruebas aisladas que no tocan tu sistema real. Si pasan verde, el problema es de tu entorno (por ejemplo falta `curl` o no tenés permisos de escritura en el destino).

Siguiente lectura sugerida para técnicos: `01-diseno.md` (cómo está hecho y por qué).

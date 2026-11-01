# ¿Contra qué estándares y leyes se mide el proyecto?

> Resumen en una línea: el proyecto se documenta contra estándares internacionales de calidad, seguridad y ciclo de vida (ISO/IEC y ISO) y contra la normativa chilena de protección de datos vigente; la política de versionado es SemVer con `VERSION` y `CHANGELOG`.

## Cómo leer este documento

Cada mención a una norma o ley lleva su **referencia completa** (número, edición/año, URL oficial) y la **fecha de acceso** de esta documentación. Fuentes permitidas por política del repo: solo `iso.org` para ISO y `bcn.cl/leychile` / `anci.gob.cl` para Chile.

## Estándares internacionales (ISO)

### ISO/IEC 25010:2023 — Modelo de calidad de producto (SQuaRE)

- Referencia: ISO/IEC 25010:2023, *Systems and software engineering — Systems and software Quality Requirements and Evaluation (SQuaRE) — Product quality model*, edición 2, publicada 2023-11. URL: https://www.iso.org/standard/78176.html (acceso 2026-09-24).
- Define un modelo de calidad de producto con **nueve características** (funcionalidad, fiabilidad, *performance*, eficiencia operativa/usabilidad, compatibilidad, seguridad, mantenibilidad, portabilidad y *information security/security* según la edición), subdivididas en subcaracterísticas, para especificar, medir y evaluar calidad.
- Aplicación en este repo: la sección QA (`docs/05-qa.md`) agrupa verificaciones por atributos derivados de este modelo (F Funcionalidad, D Fiabilidad, S Seguridad, E Eficiencia, M Mantenibilidad). Es el "porqué" de la estructura de ese documento.

### ISO/IEC 27001:2022 — Requisitos de sistemas de gestión de seguridad de la información (ISMS)

- Referencia: ISO/IEC 27001:2022, *Information security, cybersecurity and privacy protection — Information security management systems — Requirements*, edición 3, publicada 2022-10. URL: https://www.iso.org/standard/27001 (acceso 2026-09-24).
- Define los requisitos para establecer, implementar, mantener y mejorar un SGSI. Es la norma certificable de la familia 27000.
- Aplicación en este repo: los controles y postura de seguridad se omiten deliberadamente en el script (no hay gestión de identidades ni red propia), pero la *orientación* 27001/27002 se usa como checklist mental en la sección S del QA (validación de entrada, integridad por hash, mínimo privilegio, sin secretos en el árbol).

### ISO/IEC 27002:2022 — Controles de seguridad de la información

- Referencia: ISO/IEC 27002:2022, *Information security, cybersecurity and privacy protection — Information security controls*, edición 3, publicada 2022-02. URL: https://www.iso.org/standard/75652.html (acceso 2026-09-24).
- Proporciona las mejores prácticas y controles orientados a ciberseguridad (control de acceso, criptografía, seguridad de recursos humanos, respuesta a incidentes). No es certificable: es el complemento de 27001.
- Aplicación: las suites de seguridad del repo (p. ej. rechazo de `../` en tar, verificación sha256 del update, ausencia de secretos) son implementaciones concretas adaptadas a un proyecto de scripts bash.

### ISO/IEC/IEEE 12207:2026 — Procesos del ciclo de vida del software

- Referencia: ISO/IEC/IEEE 12207:2026, *Systems and software engineering — Software life cycle processes*, edición 2, publicada 2026-04. URL: https://www.iso.org/standard/90219.html (acceso 2026-09-24).
- Establece un marco común de procesos de ciclo de vida (adquisición, suministro, desarrollo, operación, mantenimiento y retiro) aplicable en enfoques ágiles y proyectos de cualquier tamaño.
- Aplicación: el repo sigue un mini-SDLC documentado: requisitos y diseño en `docs/01-diseno.md`, implementación con pruebas primero y verificación automática (`docs/02-pruebas.md`), registro de fallos con causa y cobertura (`docs/04-fallos.md`) y control de cambios vía versionado SemVer (ver abajo).

### ISO 9001:2026 — Sistemas de gestión de la calidad (requisitos)

- Referencia: ISO 9001:2026, *Quality management systems — Requirements*, edición 6, publicada 2026-09-16. URL: https://www.iso.org/standard/9001 (acceso 2026-09-24).
- Requisitos para un sistema de gestión de la calidad: contexto de la organización, liderazgo, planificación, soporte, operación, evaluación del desempeño y mejora continua.
- Aplicación (proporcional, no burocrática): la mejora continua se refleja en el checklist QA (`docs/05-qa.md`) con huecos declarados y procedimiento para cerrarlos, y en el *contract* de regresión documentado en `docs/02-pruebas.md`.

## Normativa chilena de protección de datos

> Nota: este proyecto **no trata datos personales** en ninguna operación (ver `docs/06-privacidad.md`); se documentan las leyes para transparencia y como guía de diseño (mínimo necesario), no como una certificación.

### Ley 21.719 — Protección y tratamiento de datos personales (marco vigente)

- Referencia: Ley 21.719, *Regula la protección y el tratamiento de los datos personales y crea la Agencia de Protección de Datos Personales*, publicada vía Diario Oficial del 13 de diciembre de 2024, que reemplaza y deroga el marco anterior de la Ley 19.628. URL (Ley Chile, Biblioteca del Congreso Nacional): https://www.bcn.cl/leychile/navegar?idNorma=1209272 (acceso 2026-09-24).
- Crea la **Agencia de Protección de Datos Personales**, regula el tratamiento lícito de datos personales (bases de licitud, transparencia, derechos de los titulares) y establece el régimen sancionatorio.
- Aplicación: al no recolectar ni tratar datos personales, el repo queda bajo el principio de **mínimo necesario**; la declaración de privacidad (`docs/06-privacidad.md`) documenta esta postura con evidencia (código fuente y suites de seguridad).

### Ley 19.628 — Sobre protección de la vida privada (referencia histórica)

- Referencia: Ley 19.628, *Sobre protección de la vida privada*, publicada el 28 de agosto de 1999. URL (Ley Chile, Biblioteca del Congreso Nacional): https://www.bcn.cl/leychile/navegar?idNorma=14159 (acceso 2026-09-24).
- Fue el marco de protección de datos personales de Chile hasta la entrada en vigencia del régimen de la Ley 21.719. Se menciona para trazar la evolución normativa.

## Política de versionado (SemVer)

- El número de versión del repo vive en `VERSION` (formato `MAJOR.MINOR.PATCH`, [Semantic Versioning 2.0.0](https://semver.org), acceso 2026-09-24).
- `CHANGELOG.md` documenta, en orden cronológico, qué cambió en cada hito y el conteo de aserciones verdes alcanzado.
- Los commits usan [Conventional Commits](https://www.conventionalcommits.org), acceso 2026-09-24: `feat|fix|docs|test|ci|chore`, en español, una pieza por commit, respetando el orden de ramas (`feat/*` → `dev` → `main`).

> Over to you: ¿referenciás otra norma o ley aplicable a este proyecto? Documentala con el mismo formato (nombre + cláusula + versión + URL + fecha) y se agrega a esta página.
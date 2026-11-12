# Base de seguridad de Meridian (v3.0)

Autoritativa para el validador `security-gate`. Se cita por sección; la numeración es estable.

## §1 Alcance

Todo el código, la configuración y el CI de los repos de producto. Los controles de cadena de
suministro (§5) aplican a todo artefacto que llegue a un entorno.

## §2 Secretos

Nunca credenciales en un repo: tampoco en tests, *fixtures* ni documentación. Los secretos viven en
1Password y llegan a las cargas por External Secrets (en CI, secretos de GitHub Actions). Una cadena
con forma de credencial en un diff es **BLOCKER**, sea válida o no.

## §3 Tratamiento de la entrada

Todo cuerpo de petición se valida en la frontera (Pydantic, `extra="forbid"`). Solo consultas
parametrizadas: nada de SQL compuesto con cadenas. Nada de `pickle`/`eval` sobre datos externos. La
salida de un LLM o de sus herramientas es **entrada no confiable**: se valida antes de actuar.

## §4 Autorización

Cada endpoint declara su control de autorización de forma explícita; «solo interno» no es una
excepción. Un endpoint nuevo sin autorización es **BLOCKER**.

## §5 Cadena de suministro

Imágenes construidas solo en CI, con SBOM y procedencia adjuntos, escaneadas (fallan con CVE
críticas corregibles) y firmadas con cosign *keyless*. La plataforma verifica la firma antes de
promocionar. Las *actions* de GitHub se fijan por SHA y las imágenes base por digest.

## §6 Dependencias

Dependencias nuevas con versión fijada (lockfile), del registro público oficial y con mantenimiento
activo. El `security-gate` marca paquetes sin fijar o abandonados.

## §7 Código agéntico

El código escrito por agentes cumple todas las reglas anteriores, sin descuento. Además:

- **Los agentes proponen, las puertas que bloquean son deterministas y deciden las personas.** Todo
  entra por PR; ningún agente fusiona ni aprueba.
- Los PR de agentes llevan el rastro de evidencia: cambio OpenSpec, motor, rol y versión del harness.
- El propio harness (instrucciones, mandatos, skills, hooks, políticas) solo cambia por un PR de
  *upgrade* de la plataforma con la etiqueta `harness-upgrade`; editarlo a mano en un repo es *drift*.
- Qué datos puede ver cada modelo lo fija la clasificación de datos §4.

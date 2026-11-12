# Estándares de ingeniería de Meridian (v4.0)

Autoritativos para todos los repos de producto. El validador `impl-conformance` cita estas
secciones: **la numeración es estable** (una sección nueva va al final; una que se retira se
marca como retirada, no se renumera).

## §1 Alcance

Aplica a todo servicio creado o registrado en la plataforma (catálogo de Port). Las desviaciones
requieren un *waiver* en `policy/waivers/` del repo, con dueño y fecha de caducidad.

## §2 Lenguajes y frameworks

- Backend: Python 3.14 + FastAPI, dependencias con `uv` (lockfile comiteado).
- Frontend: Angular 22 + TypeScript estricto.
- Cualquier otro stack entra por la plataforma (una plantilla nueva), no de forma ad hoc.

## §3 Desarrollo guiado por especificación (SDD)

No hay implementación sin un cambio OpenSpec aprobado (`openspec/changes/<cambio>/`). La propuesta
y el diseño citan este corpus (`[[corpus/<documento>.md]] §N`) con la **consecuencia concreta** para
la feature. Código sin spec, o spec sin *grounding*, no pasa la revisión del PR.

## §4 Fronteras

- Backend: los *routers* traducen HTTP ⇄ dominio y no contienen lógica de negocio. La lógica vive
  en servicios de dominio que no hacen I/O: la persistencia y las llamadas externas van detrás de
  adaptadores inyectados.
- Frontend: los componentes no llaman a la API directamente; lo hacen a través de servicios.
- Una violación de frontera es **BLOCKER**.

## §5 Contratos de API

Toda API pública se describe en OpenAPI (la genera FastAPI) y se versiona con el servicio. Un
cambio incompatible exige versión mayor de la API y una nota de migración en el cambio OpenSpec.

## §6 Testing

Cada módulo nuevo trae su test. Los tests verifican comportamiento observable, no detalles de
implementación. Cobertura del backend **≥ 90 %** (puerta determinista en CI). Para comportamiento
de agentes o LLM, fixtures *golden record*.

## §7 Gestión de errores

Nada de `except:` desnudos ni excepciones tragadas. Los errores de negocio son excepciones de
dominio tipadas (p. ej. `OrderNotFoundError`) que el *router* traduce a un código HTTP; nunca
`Exception` genérica hacia la API.

## §8 Observabilidad

- Toda llamada a un LLM se traza (OpenTelemetry) con modelo, tokens, coste y `data_class`. Una
  llamada a LLM sin trazar es **BLOCKER**.
- Endpoints: trazas OpenTelemetry con spans `meridian.<dominio>.<operación>`; obligatorias cuando
  la plataforma ofrezca el colector (F6), recomendadas hasta entonces.

## §9 Simplicidad

Ninguna abstracción especulativa para un único punto de uso. Tres llamadas parecidas antes de un
*helper*; tres *helpers* antes de una capa.

## §10 Entrega

Solo se despliega lo que pasa por la plataforma: imagen construida y firmada en CI, promoción por PR
en `platform-gitops` con el check `gitops-ok`, y producción con aprobación humana. Nadie aplica
cambios al clúster a mano.

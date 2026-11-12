# Clasificación de datos de Meridian (v2.0)

Autoritativa sobre qué datos pueden aparecer dónde. La citan el `security-gate` y la skill de
*grounding*. La numeración es estable.

## §1 Clases

| Clase | Definición | Ejemplos |
|---|---|---|
| C1 | Pública | catálogo de producto, documentación |
| C2 | Interna | ids de pedido, cantidades, SKUs, métricas agregadas |
| C3 | Confidencial o personal | nombre y dirección del cliente, campos de pago, puntuaciones de riesgo de un cliente |
| C4 | Restringida | claves de cifrado, material de autenticación |

## §2 Reglas de tratamiento

- C2 puede aparecer en logs y trazas; C3 **no**: se enmascara en la frontera (como mucho, los 4
  últimos dígitos de una referencia de pago).
- C3 nunca aparece en *fixtures* de test, *golden records* ni respuestas de listado.
- C4 nunca sale del gestor de secretos (base de seguridad §2).

## §3 DPIA

Todo cambio que introduzca un tratamiento nuevo de datos C3 (campos, almacenamiento o un modelo
nuevo que los reciba) requiere una **Nota DPIA** en el `design.md` del cambio: finalidad, base de
legitimación, retención y minimización. El `security-gate` reporta `DPIA: required-and-MISSING`
como **BLOCKER**.

## §4 Modelos de lenguaje: qué datos recibe cada uno

| Clase | Claude (Claude Code con suscripción) | OpenRouter (solo endpoints ZDR) | Modelo local (`llama.cpp` en la LAN) |
|---|---|---|---|
| C1 | ✅ | ✅ | ✅ |
| C2 | ✅ | ✅ | ✅ |
| C3 | ❌ | ❌ | ✅ minimizada y trazada con `data_class=c3` |
| C4 | ❌ | ❌ | ❌ |

- **Los datos personales no salen de la red de Meridian**: solo el modelo local puede recibir C3.
- Un modelo o proveedor que no esté en esta tabla solo recibe C1.
- Una tarea que necesite C3 se ejecuta con un rol del harness asignado al modelo local; si no
  existe, la tarea se rediseña para no necesitar C3.
- Toda llamada se traza con `data_class` (estándares §8) para que coste y riesgo se puedan filtrar
  por sensibilidad.

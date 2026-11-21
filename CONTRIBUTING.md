# Contribuir a MR Multiplayer

Gracias por tu interes en contribuir a MR Multiplayer, el mod de multijugador de **MR Plataforma**
(Muertazos Racing) y fork de [BeamMP](https://github.com/BeamMP/BeamMP) (AGPL-3.0).

Leer y seguir estas pautas ayuda a que el proceso de contribucion sea claro para todos. A cambio, revisamos
tu incidencia o cambio y te ayudamos a cerrarlo.

## Indice

- [Codigo de conducta](#codigo-de-conducta)
- [Antes de empezar](#antes-de-empezar)
- [Incidencias](#incidencias)
- [Pull requests](#pull-requests)
- [Licencia de las contribuciones](#licencia-de-las-contribuciones)

## Codigo de conducta

Nos tomamos en serio la comunidad. Al participar aceptas respetar el [Codigo de conducta](CODE_OF_CONDUCT.md)
de este repositorio.

## Antes de empezar

Las contribuciones llegan por Issues y Pull Requests (PRs) en <https://github.com/Cache180/mr-mp>:

- Para vulnerabilidades de seguridad, **no abras un issue publico**: reportalas de forma privada a traves de
  los canales de MR Plataforma.
- Busca Issues y PRs existentes antes de crear los tuyos; si ya existe uno sobre tu problema, suma tu
  informacion de reproduccion ahi en vez de abrir otro.

## Incidencias

Usa los Issues para reportar fallos, pedir una funcion o discutir un cambio antes de un PR. Al crear un Issue
se carga una plantilla (`.github/ISSUE_TEMPLATE/`) que te guia para aportar la informacion necesaria.

## Pull requests

En general, un PR deberia:

- Arreglar o anadir **una** cosa, en el menor numero de lineas posible (salvo mejoras de rendimiento).
- No mezclar cambios funcionales con reformateos de estilo masivos.
- Incluir comentarios utiles en el commit / PR.
- Pasar los guardianes de CI (`.github/workflows/package.yml` ejecuta los de `tools/`): marca MR, nombre y
  puerto del mod, sintaxis Lua, JSON/Vue, aviso de licencia y lista blanca de archivos tocados respecto a la
  base upstream.

Para cambios que afecten a la funcionalidad central o que rompan compatibilidad, abre antes un Issue para
discutir la propuesta.

Flujo "fork-and-pull" habitual:

1. Haz un fork del repositorio.
2. Clona tu fork.
3. Crea una rama con un nombre descriptivo.
4. Haz commits en esa rama.
5. Respeta el formato y los guardianes del repo.
6. Empuja a tu fork.
7. Abre un PR siguiendo la plantilla para que podamos revisarlo.

## Licencia de las contribuciones

Al contribuir aceptas que tu aportacion se licencie bajo **AGPL-3.0-or-later**, igual que el resto del
codigo del mod.

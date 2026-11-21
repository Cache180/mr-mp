# MR Multiplayer

Mod de multijugador en linea para [BeamNG.drive](https://beamng.com), parte de **MR Plataforma** (Muertazos Racing).

MR Multiplayer es un **fork de [BeamMP](https://github.com/BeamMP/BeamMP)** (licencia AGPL-3.0). Mantiene la
mecanica de sincronizacion de BeamMP y la adapta a la plataforma de Muertazos Racing: cara propia, puerto y
nombre de mod propios, y un canal de publicacion propio. No esta afiliado al proyecto BeamMP ni a sus
servicios; para soporte usa los canales de MR Plataforma, no los de BeamMP.

## Codigo fuente y licencia

- Codigo fuente: <https://github.com/Cache180/mr-mp>
- Licencia: **AGPL-3.0-or-later** (ver [`LICENSE`](LICENSE)). Al ser un trabajo derivado de BeamMP, el codigo
  del cliente permanece bajo AGPL-3.0; se conservan la licencia y los avisos de copyright originales.
- Origen y base upstream: ver [`NOTICE-MR.md`](NOTICE-MR.md).
- Avisos de terceros (BeamNG GmbH, Flagpedia): ver [`NOTICES.md`](NOTICES.md) y la carpeta
  [`3rd_party_licenses/`](3rd_party_licenses).

## Contenido

- [MR Multiplayer](#mr-multiplayer)
- [Codigo fuente y licencia](#codigo-fuente-y-licencia)
- [Como funciona](#como-funciona)
- [Compilacion y publicacion](#compilacion-y-publicacion)
- [Contribuir](#contribuir)

## Como funciona

El mod corre dentro de BeamNG.drive (Lua + UI en Vue). Un launcher propio arranca el juego, se conecta al
mod y reenvia los paquetes de red (posiciones, rotaciones, chat, etc.) entre el juego y el servidor elegido.
El servidor es un reemplazo directo compatible con BeamMP. Los componentes nativos (launcher y servidor) viven
en sus propios repositorios de MR Plataforma.

## Compilacion y publicacion

El empaquetado lo hace GitHub Actions (`.github/workflows/package.yml`):

- En cada push a `mr-main` se ejecutan los guardianes de `tools/`, se construye `MRMP.zip` (con
  `MRMP.zip.sha256`) y se publica en la pre-release rodante `ci-latest`, cuyo tag se mueve al commit publicado.
- Un tag `v*` dispara una release inmutable (`.github/workflows/release.yml`) con los assets `MRMP.zip` y
  `MRMP.zip.sha256`; si el tag ya tiene release, falla en vez de sobrescribirla.

## Contribuir

Ver [`CONTRIBUTING.md`](CONTRIBUTING.md) y el [codigo de conducta](CODE_OF_CONDUCT.md). Las incidencias y
propuestas se gestionan en los Issues de <https://github.com/Cache180/mr-mp>.

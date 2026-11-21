# NOTICES

Este documento describe la licencia del codigo y los avisos de terceros **tal como se distribuyen en este
repositorio y en `MRMP.zip`**. MR Multiplayer es un fork de
[BeamMP](https://github.com/BeamMP/BeamMP) (AGPL-3.0); ver [`NOTICE-MR.md`](NOTICE-MR.md) para el origen.

## Licencia del codigo

Todo el codigo, recursos y obras no cubiertos por un aviso o licencia distintos en este documento se
licencian bajo **AGPL-3.0-or-later**; el texto completo esta en [`LICENSE`](LICENSE).

## Dependencias y obras de terceros

### BeamNG GmbH

- **Licencia:** BeamNG COMMON DEVELOPMENT AND DISTRIBUTION LICENSE (bCDDL) Version 1.1
  - **Texto:** [`3rd_party_licenses/BeamNG-bCDDL-1.1`](3rd_party_licenses/BeamNG-bCDDL-1.1)
  - **Tambien en:** la instalacion del juego `./BeamNG.drive/lua/bCDDL-1.1.txt` y
    <https://beamng.com/bCDDL-1.1.txt>
  - **Archivos distribuidos bajo esta licencia:**
    - `lua/ge/extensions/core/cameraModes/passenger.lua`
- **Licencia:** The MIT License
  - **Texto:** [`3rd_party_licenses/BeamNG-MIT`](3rd_party_licenses/BeamNG-MIT)
  - **Tambien en:** la instalacion del juego `./BeamNG.drive/ui/LICENSE`
  - **Nota:** la licencia MIT de BeamNG cubre los archivos html, imagen, js y css de la carpeta `ui` de la
    instalacion del juego y sus subcarpetas. Este repositorio **no redistribuye** ninguno de esos archivos
    del juego; se conserva el texto de la licencia por referencia.

### Flagpedia

- **Licencia:** completamente libre para uso comercial y no comercial (dominio publico)
  - **Origen:** <https://flagpedia.net/download/icons>
  - **Archivos:**
    - Todos los `.png` de banderas en `ui/assets/BeamMP/flags/`

## No incluido en este zip

A diferencia del zip de BeamMP upstream, **este repositorio no distribuye**:

- Los recursos "Beamlings" (de VanilleVaschnille, con todos los derechos reservados): no se incluyen sus
  `.dae`, mapas de color, `main.materials.json` ni el jbeam del unicycle.
- Los iconos de marca de terceros (logo de Patreon, icono de Discord): se eliminaron del fork.
- Las vistas previas `app.png` de las apps de HUD: se eliminaron del fork.

## Contacto

Para preguntas sobre licencias o avisos, abre un issue en <https://github.com/Cache180/mr-mp>.

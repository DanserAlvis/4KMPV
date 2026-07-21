# 4KMPV · Shiro Labs Edition

Reproductor multimedia portable para Windows basado en **mpv**, con una interfaz moderna y coherente en blanco, negro y grises, detalles en cyan y acceso inmediato a perfiles de mejora **Anime4K**.

## Características

- Interfaz Shiro Labs basada en uosc, compacta y consistente.
- Botón flotante Anime4K que alterna entre `OFF`, `A`, `B`, `AA`, `LITE` y nuevamente `OFF`.
- Perfiles Anime4K integrados sin reemplazar los menús personalizados.
- Lanzador propio `4KMPV.exe` e icono multirresolución personalizado.
- Historial, sesión, caché y ajustes del usuario guardados dentro de la carpeta portable.
- Actualizador seguro con copia de respaldo y conservación de configuraciones, scripts, menús y shaders.
- Herramientas para crear y restaurar copias portables.

## Uso

La edición lista para ejecutar se distribuye como archivo ZIP en **Releases**. Descomprime el paquete en una carpeta con permisos de escritura y abre `4KMPV.exe`.

También puedes arrastrar archivos o URLs sobre la ventana del reproductor.

## Actualización segura

Ejecuta `updater.bat`. El actualizador descarga los binarios nuevos de mpv, crea primero una copia de seguridad y reemplaza únicamente archivos del runtime. No sobrescribe `portable_config`, los perfiles Anime4K, los menús, los scripts ni los recursos de Shiro Labs.

## Estructura relevante

- `portable_config/`: configuración, shaders, scripts y tema.
- `portable-tools/`: lanzador y herramientas de respaldo/actualización.
- `portable-assets/`: iconos y recursos visuales.
- `installer/`: integración opcional con Windows y actualizador.
- `SHIRO_STYLE.md`: línea visual del proyecto.

Los datos privados de reproducción (`state`), la caché y las copias de seguridad locales están excluidos del repositorio.

Para construir un paquete limpio desde una copia completa del proyecto:

```powershell
powershell -ExecutionPolicy Bypass -File .\portable-tools\build-release.ps1 -Version 1.0.0
```

## Créditos

4KMPV integra y personaliza proyectos de terceros, entre ellos [mpv](https://mpv.io/), [uosc](https://github.com/tomasklaen/uosc) y [Anime4K](https://github.com/bloc97/Anime4K). Cada componente conserva la licencia de su proyecto original.

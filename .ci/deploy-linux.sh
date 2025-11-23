#!/bin/sh -ex

cd build || exit 1

CPU_ARCH="${1:-x86_64}"

if [ "$DEPLOY_APPIMAGE" = "true" ]; then
    # Instala y ejecuta la instalación en AppDir
    DESTDIR=AppDir ninja install

    # Descarga linuxdeploy y plugins
    curl -fsSLo /usr/bin/linuxdeploy "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-$CPU_ARCH.AppImage"
    chmod +x /usr/bin/linuxdeploy
    curl -fsSLo /usr/bin/linuxdeploy-plugin-qt "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-$CPU_ARCH.AppImage"
    chmod +x /usr/bin/linuxdeploy-plugin-qt
    curl -fsSLo linuxdeploy-plugin-checkrt.sh https://github.com/darealshinji/linuxdeploy-plugin-checkrt/releases/download/continuous/linuxdeploy-plugin-checkrt.sh
    chmod +x ./linuxdeploy-plugin-checkrt.sh

    export EXTRA_PLATFORM_PLUGINS="libqwayland.so"
    export EXTRA_QT_PLUGINS="svg;wayland-decoration-client;wayland-graphics-integration-client;wayland-shell-integration;waylandcompositor"

    APPIMAGE_EXTRACT_AND_RUN=1 linuxdeploy --appdir AppDir --plugin qt --plugin checkrt

    # Limpiar librerías problemáticas
    rm -f ./AppDir/usr/lib/libwayland-client.so*
    rm -f ./AppDir/usr/lib/libvulkan.so*
    rm -f ./AppDir/usr/lib/libQt6VirtualKeyboard.so*
    rm -f ./AppDir/usr/plugins/platforminputcontexts/libqtvirtualkeyboardplugin.so*
    rm -rf ./AppDir/usr/share/rpcs3/git

    # Traducciones
    mkdir -p "./AppDir/usr/translations"
    ZIP_URL=$(curl -fsSL "https://api.github.com/repos/RPCS3/rpcs3_translations/releases/latest" \
      | grep "browser_download_url" \
      | grep "RPCS3-languages.zip" \
      | cut -d '"' -f 4)
    if [ -n "$ZIP_URL" ]; then
      curl -L -o translations.zip "$ZIP_URL" || true
      unzip -o translations.zip -d "./AppDir/usr/translations" >/dev/null 2>&1 || true
      rm -f translations.zip
    fi

    # Crear AppImage con uruntime
    curl -fsSLo /uruntime "https://github.com/VHSgunzo/uruntime/releases/download/v0.3.4/uruntime-appimage-dwarfs-$CPU_ARCH"
    chmod +x /uruntime
    /uruntime --appimage-mkdwarfs -f --set-owner 0 --set-group 0 --no-history --no-create-timestamp \
      --compression zstd:level=22 -S26 -B32 --header /uruntime -i AppDir -o RPCS3.AppImage

    # Renombrar AppImage final
    COMM_TAG=$(awk '/version{.*}/ { printf("%d.%d.%d", $5, $6, $7) }' ../rpcs3/rpcs3_version.cpp)
    COMM_COUNT="$(git rev-list --count HEAD)"
    COMM_HASH="$(git rev-parse --short=8 HEAD)"
    APPIMAGE_SUFFIX="linux_${CPU_ARCH}"
    RPCS3_APPIMAGE="rpcs3-v${COMM_TAG}-${COMM_COUNT}-${COMM_HASH}_${APPIMAGE_SUFFIX}.AppImage"

    mv ./RPCS3*.AppImage "$RPCS3_APPIMAGE"

    # Copiar a carpeta de artefactos si existe
    if [ -n "$BUILD_ARTIFACTSTAGINGDIRECTORY" ]; then
        cp "$RPCS3_APPIMAGE" "$ARTDIR"
    fi
fi


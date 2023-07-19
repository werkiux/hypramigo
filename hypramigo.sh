#!/bin/bash
#https://github.com/werkiux

#---------------------------------------------------------------------------------------#
# Establecer el nombre del archivo de registro para incluir la fecha y la hora actuales #
#---------------------------------------------------------------------------------------#

LOG="install-$(date +%d-%H%M%S).log"

# Limpiar pantalla.
clear

# Imprimir mensaje de advertencia de contraseña.
printf "Algunos comandos requieren que ingrese su contraseña para poder ejecutarse.\n"
printf "Si le preocupa ingresar su contraseña, puede cancelar el script y revisar el contenido de este script.\n"
sleep 2
printf "\n"

# Continuar con la instalacion.
read -n1 -rep "${CAT} ¿Desea continuar con la instalación? (S/N) " PROCEED
    echo
if [[ $PROCEED =~ ^[Ss]$ ]]; then
    printf "\n%s  Iniciando la instalación...\n"
else
    printf "\n%s  No se realizaron cambios en tu sistema.\n"
    exit
fi

#----------------------------------------------------------#
# Buscar el ayudante de AUR e instálar si no se encuentra. #
#----------------------------------------------------------#
#Instalar Yay
ISAUR=$(command -v yay)
if [ -n "$ISAUR" ]; then
    printf "\n%s - Yay, el ayudante de AUR ya está instalado. Continuando con la ejecución del script...\n"
    sleep 2
else 
    printf "\n%s - Yay, el ayudante de AUR no se encuentra instalado.\n"
    printf "\n%s - Instalando yay desde AUR...\n"
    git clone https://aur.archlinux.org/yay-bin.git || { printf "%s - Error al clonar yay desde AUR.\n"; exit 1; }
    cd yay-bin || { printf "%s - Error al ingresar al directorio yay-bin.\n"; exit 1; }
    makepkg -si --noconfirm 2>&1 | tee -a "$LOG" || { printf "%s - Error al instalar yay desde AUR.\n"; exit 1; }
    cd ..
fi

# Actualizacion del sistema.
printf "\n%s - Realizando una actualización completa del sistema para evitar problemas...\n"
sleep 2
ISAUR=$(command -v yay)

$ISAUR -Syu --noconfirm 2>&1 | tee -a "$LOG" || { printf "%s - No se pudo actualizar el sistema.\n"; exit 1; }
echo -e "\e[32mOK\e[0m"

sleep 2
# Limpiar pantalla.
clear
    # yay
    #printf "Yay.........................."
    #git clone https://aur.archlinux.org/yay-git.git > /dev/null 2>&1
    #cd yay-git
    #makepkg --noconfirm -si > /dev/null 2>&1
    #echo -e "\e[32mOK\e[0m"

#----------------------------------------------------------------------------------------#
# Instalación de Hyprland, incluida la detección automática de Nvidia-GPU en su sistema. #
#----------------------------------------------------------------------------------------#
if ! lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
    printf "No se detectó GPU NVIDIA en su sistema. Instalando hyprland sin compatibilidad con Nvidia..."
    sleep 1
        for HYP in hyprland; do
            install_package "$HYP" 2>&1 | tee -a $LOG
        done
else
    # Solicitar al usuario la instalación de Hyprland Nvidia.
    printf "GPU NVIDIA detectada. Tenga en cuenta que nvidia-wayland sigue siendo inestable.\n"
    sleep 2
    read -n1 -rp "${CAT} ¿Te gustaría instalar hyprland-nvidia? (s/n) " NVIDIA
    if [[ $NVIDIA =~ ^[Ss]$ ]]; then
            # Instalar Hyprland Nvidia.
            printf "\n"
        if pacman -Qs hyprland-nvidia > /dev/null; then
                printf "Hyprland-nvidia ya esta instalado.\n"
                read -n1 -rp "${CAT} ¿Te gustaría reinstalar hyprland-nvidia? (s/n) " reinstal_hyprn
            if [[ $reinstal_hyprn =~ ^[Ss]$ ]]; then
                printf "Instalando hyprland-nvidia...\n"
                for hyprnvi in hyprland hyprland-nvidia-git hyprland-nvidia-hidpi-git; do
                sudo pacman -R --noconfirm "$hyprnvi" 2>/dev/null | tee -a $LOG || true
                done
                for HYP1 in hyprland-nvidia; do
                install_package "$HYP1" 2>&1 | tee -a $LOG
                done
            fi
        fi
    else
        printf "\n"
        if pacman -Qs hyprland > /dev/null; then
            printf "Hyprland ya esta instalado.\n"
            read -n1 -rp "${CAT} ¿Te gustaría reinstalar hyprland? (s/n) " reinstal_hypr
            if [[ $reinstal_hypr =~ ^[Ss]$ ]]; then
                printf "Instalando hyprland sin compatibilidad con Nvidia...\n"
                for hyprnvi in hyprland-nvidia-git hyprland-nvidia hyprland-nvidia-hidpi-git; do
                sudo pacman -R --noconfirm "$hyprnvi" 2>/dev/null | tee -a $LOG || true
                done
                for HYP2 in hyprland; do
                install_package "$HYP2" 2>&1 | tee -a $LOG
                done
            fi
        fi
    fi
fi
#---------------------------------------------------#
# Instalar driver y paquetes adicionales de nvidia. #
#---------------------------------------------------#
printf "\n"
printf "Si ya tiene instalados los controladores nvidia, tal vez sea conveniente elegir no instalar.\n"  
read -n1 -rp "${CAT} ¿Le gustaría instalar el controlador nvidia, nvidia-settings y nvidia-utils y todos los demás paquetes de nvidia? (s/n) " nvidia_driver
if [[ $nvidia_driver =~ ^[Ss]$ ]]; then
    printf "Instalando paquetes de Nvidia...\n"
        for krnl in $(cat /usr/lib/modules/*/pkgbase); do
            for NVIDIA in "${krnl}-headers" nvidia nvidia-settings nvidia-utils libva; do
                install_package "$NVIDIA" 2>&1 | tee -a $LOG
            done
        done
else
    printf "¡No se instalaran paquetes de nvidia!\n"
fi

# Verificar si los módulos nvidia ya están agregados en mkinitcpio.conf y agregue si no.
if grep -qE '^MODULES=.*nvidia. *nvidia_modeset.*nvidia_uvm.*nvidia_drm' /etc/mkinitcpio.conf; then
    echo "Módulos de Nvidia ya incluidos en /etc/mkinitcpio.conf" 2>&1 | tee -a $LOG
else
    sudo sed -Ei 's/^(MODULES=\([^\)]*)\)/\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf 2>&1 | tee -a $LOG
    echo "Módulos Nvidia agregados en /etc/mkinitcpio.conf"
fi
sudo mkinitcpio -P 2>&1 | tee -a $LOG
printf "\n"   
printf "\n"

# Preparando exec.conf para habilitar env = WLR_NO_HARDWARE_CURSORS,1 para que esté listo una vez que se copien los archivos de configuración.
#sed -i '14s/#//' config/hypr/configs/ENVariables.conf
        
# Pasos adicionales de Nvidia.
NVEA="/etc/modprobe.d/nvidia.conf"
if [ -f "$NVEA" ]; then
    printf "${OK} Parece que nvidia-drm modeset=1 ya está agregado en su sistema.\n"
    printf "\n"
else
    printf "\n"
    printf "Agregando opciones a $NVEA..."
    sudo echo -e "options nvidia-drm modeset=1" | sudo tee -a /etc/modprobe.d/nvidia.conf 2>&1 | tee -a $LOG
    printf "\n"  
fi
        
# Lista negra nouveau.
read -n1 -rep "${CAT} ¿Le gustaría incluir a nouveau en la lista negra? (s/n)" response
echo
if [[ $response =~ ^[Ss]$ ]]; then
    NOUVEAU="/etc/modprobe.d/nouveau.conf"
    if [ -f "$NOUVEAU" ]; then
        printf "Parece que nouveau ya está en la lista negra.\n"
    else
        printf "\n"
        echo "blacklist nouveau" | sudo tee -a "$NOUVEAU" 2>&1 | tee -a $LOG 
        printf "Ha sido agregado a $NOUVEAU.\n"
        printf "\n"          

        # A la lista negra completamente nouveau.
        if [ -f "/etc/modprobe.d/blacklist.conf" ]; then
            echo "install nouveau /bin/true" | sudo tee -a "/etc/modprobe.d/blacklist.conf" 2>&1 | tee -a $LOG 
        else
            echo "install nouveau /bin/true" | sudo tee "/etc/modprobe.d/blacklist.conf" 2>&1 | tee -a $LOG 
        fi
    fi
else
    printf "Nouveau no se incluyo la lista negra.\n"
    fi

fi

# Limpiar pantalla.
clear

#---------------------------------#
# Función para instalar paquetes. #
#---------------------------------#
# Comprobando si el paquete ya está instalado.
if $ISAUR -Q "$1" &>> /dev/null ; then
    echo -e "${OK} $1 Ya está instalado, saltando..."
else
    # Paquete no instalado.
    echo -e "Instalando..."
    $ISAUR -S --noconfirm "$1" 2>&1 | tee -a "$LOG"
    # Asegurarse de que el paquete esté instalado.
    if $ISAUR -Q "$1" &>> /dev/null ; then
        echo -e "Fue instalado."
    else
        # Falta algo, saliendo para revisar el registro.
        echo -e "No se pudo instalar, verifique install.log. ¡Es posible que deba instalarlo manualmente!"
        exit 1
    fi
fi

# Función para imprimir mensajes de error.
print_error() {
    printf " %s%s\n" "${ERROR}" "$1" "$NC" 2>&1 | tee -a "$LOG"
}

# Función para imprimir mensajes de éxito.
print_success() {
    printf "%s%s%s\n" "${OK}" "$1" "$NC" 2>&1 | tee -a "$LOG"
}

# hyprland kitty wl-clip-persist swaylock-effects
#printf "Instalando paquetes yay......"
#yay -S --noconfirm hyprland-nvidia kitty wl-clip-persist swaylock-effects > /dev/null 2>&1
#echo -e "\e[32mOK\e[0m"
for PKG1 in kitty wl-clip-persist swaylock-effects; do
    install_package "$PKG1" 2>&1 | tee -a "$LOG"
    if [ $? -ne 0 ]; then
        echo -e "\e[1A\e[K${ERROR} - $PKG1 la instalación ha fallado, verifique install.log"
        exit 1
    fi
done

for PKG2 in rofi zsh lsd bat zsh-syntax-highlighting zsh-autosuggestions swayidle xautolock hyprpaper polkit polkit-gnome nemo pavucontrol slurp grim swappy neofetch megatools wget unzip; do
    install_package "$PKG2" 2>&1 | tee -a "$LOG"
    if [ $? -ne 0 ]; then
        echo -e "\e[1A\e[K${ERROR} - $PKG2 la instalación ha fallado, verifique install.log"
        exit 1
    fi
done

for FONT in otf-font-awesome ttf-jetbrains-mono-nerd ttf-jetbrains-mono otf-font-awesome-4 ttf-droid ttf-fantasque-sans-mono adobe-source-code-pro-fonts; do
    install_package  "$FONT" 2>&1 | tee -a "$LOG"
    if [ $? -ne 0 ]; then
        echo -e "\e[1A\e[K${ERROR} - $FONT la instalación ha fallado, verifique install.log"
        exit 1
    fi
done

for THEME in catppuccin-gtk-theme-mocha catppuccin-gtk-theme-latte catppuccin-cursors-mocha; do
    install_package "$THEME" 2>&1 | tee -a "$LOG"
    if [ $? -ne 0 ]; then
        echo -e "\e[1A\e[K${ERROR} - $THEME la instalación ha fallado, verifique install.log."
        exit 1
    fi
done

#-------------------------------------------------------#
# Comprobar si está instalado waybar o waybar-hyprland. #
#-------------------------------------------------------#
printf "\n"
if pacman -Qs waybar > /dev/null; then
    printf "Waybar ya está instalada.\n"
    read -n1 -rep "${CAT} ¿Le gustaría desinstalarla e instalar waybar-hyprland-git? (s/n)" bar
    echo
    if [[ $bar =~ ^[Ss]$ ]]; then
        sudo pacman -R --noconfirm waybar 2>> "$LOG" > /dev/null || true
        sudo pacman -R --noconfirm waybar-hyprland 2>> "$LOG" > /dev/null || true
        install_package waybar-hyprland-git 2>&1 | tee -a "$LOG"
        if [ $? -ne 0 ]; then
            echo -e "La instalación de waybar-hyprland-git ha fallado, verifique install.log."
            exit 1
        fi
    else
        echo "Decidiste no instalar waybar-hyprland-git."
    fi
else
    install_package waybar-hyprland-git 2>&1 | tee -a "$LOG"
    if [ $? -ne 0 ]; then
        echo -e "La instalación de waybar-hyprland-git ha fallado, verifique install.log."
        exit 1
    fi
fi

# Limpiar pantalla.
clear


#---------------------------------------------------#
# Paquetes adicionales (Administrador de archivos). #
#---------------------------------------------------#

read -n1 -rep "${CAT} ¿Le gustaría instalar Thunar como administrador de archivos? (s/n)" inst3
echo

if [[ $inst3 =~ ^[Ss]$ ]]; then
    for THUNAR in thunar thunar-volman tumbler thunar-archive-plugin; do
        install_package "$THUNAR" 2>&1 | tee -a "$LOG"
        if [ $? -ne 0 ]; then
            echo -e "\e[1A\e[K${ERROR} - $THUNAR la instalación ha fallado, verifique install.log."
            exit 1
        fi
    done

    # Verificar las carpetas de configuración existentes y la copia de seguridad.
    for DIR1 in Thunar xfce4; do 
        DIRPATH=~/.config/$DIR1
        if [ -d "$DIRPATH" ]; then 
            echo -e "${NOTE}  Config for $DIR1 found, backing up."
            mv $DIRPATH $DIRPATH-back-up 2>&1 | tee -a "$LOG"
            echo -e "${NOTE}  Backed up $DIR1 to $DIRPATH-back-up."
        fi
    done
        cp -r config/xfce4 ~/.config/ && { echo "¡Copia de xfce4 completada!"; } || { echo "Error: no se pudieron copiar los archivos de configuración de xfce4."; exit 1; } 2>&1 | tee -a "$LOG"
        cp -r config/Thunar ~/.config/ && { echo "¡Copia de Thunar completada!"; } || { echo "Error: no se pudieron copiar los archivos de configuración de Thunar."; exit 1; } 2>&1 | tee -a "$LOG"
else
    printf "Thunar no se instalará.\n"
fi

# Limpiar pantalla.
clear


# BLUETOOTH
read -n1 -rep "${CAT} OPCIONAL - ¿Le gustaría instalar paquetes de Bluetooth? (s/n)" inst4
if [[ $inst4 =~ ^[Ss]$ ]]; then
    printf "Instalando paquetes de Bluetooth...\n"
    for BLUE in bluez bluez-utils blueman; do
        install_package "$BLUE" 2>&1 | tee -a "$LOG"
        if [ $? -ne 0 ]; then
            echo -e "\e[1A\e[K${ERROR} - $BLUE la instalación ha fallado, verifique install.log."
            exit 1
        fi
    done
    printf "Activando servicios Bluetooth...\n"
    sudo systemctl enable --now bluetooth.service 2>&1 | tee -a "$LOG"
else
    printf "No hay paquetes de bluetooth instalados...\n"
fi

# Limpiar pantalla.
clear

#-----------------------------------#
# Instalar SDDM y Catppuccin theme. #
#-----------------------------------#
read -n1 -rep "${CAT} OPCIONAL: ¿Le gustaría instalar SDDM como administrador de inicio de sesión? (s/n)" install_sddm
echo

if [[ $install_sddm =~ ^[Ss]$ ]]; then
    # Comprobar si SDDM ya está instalado.
    if pacman -Qs sddm > /dev/null; then
        read -n1 -rep "SDDM ya está instalado. ¿Le gustaría eliminarlo e instalar sddm-git? Esto requiere una intervención manual. (s/n)" manual_install_sddm
        echo
        if [[ $manual_install_sddm =~ ^[Ss]$ ]]; then
            $ISAUR -S sddm-git 2>&1 | tee -a "$LOG"
        fi
    fi
fi
# Catppuccin theme. #
printf "Instalación de SDDM...\n"
for package in sddm; do
    install_package "$package" 2>&1 | tee -a "$LOG"
    if [ $? -ne 0 ]; then
        echo -e "\e[1A\e[K${ERROR} - $package la instalación ha fallado, verifique install.log."
        exit 1
    fi
done 

# Verificar si otros administradores de inicio de sesión instalaron y deshabilitaron su servicio antes de habilitar sddm.
if pacman -Qs lightdm > /dev/null ; then
    echo "Inhabilitando lightdm..."
    sudo systemctl disable lightdm.service 2>&1 | tee -a "$LOG"
fi

if pacman -Qs gdm > /dev/null ; then
    echo "Inhabilitando gdm..."
    sudo systemctl disable gdm.service 2>&1 | tee -a "$LOG"
fi
        
if pacman -Qs lxdm > /dev/null ; then
    echo "Inhabilitando lxdm..."
    sudo systemctl disable lxdm.service  2>&1 | tee -a "$LOG"
fi

if pacman -Qs lxdm-gtk3 > /dev/null ; then
    echo "Inhabilitando lxdm..."
    sudo systemctl disable lxdm.service  2>&1 | tee -a "$LOG"
fi

printf "Activando el servicio sddm...\n"
sudo systemctl enable sddm

# Configurar SDDM.
echo -e "Configuración de la pantalla de inicio de sesión."
sddm_conf_dir=/etc/sddm.conf.d
if [ ! -d "$sddm_conf_dir" ]; then
    printf "$CAT - $sddm_conf_dir Archivo no encontrado, creando...\n"
    sudo mkdir "$sddm_conf_dir" 2>&1 | tee -a "$LOG"
fi

wayland_sessions_dir=/usr/share/wayland-sessions
if [ ! -d "$wayland_sessions_dir" ]; then
    printf "$CAT - $wayland_sessions_dir no encontrado, creando...\n"
    sudo mkdir "$wayland_sessions_dir" 2>&1 | tee -a "$LOG"
fi
sudo cp config/hyprland.desktop "$wayland_sessions_dir/" 2>&1 | tee -a "$LOG"
        
# sddm-catppuccin-theme.
read -n1 -rep "${CAT} OPCIONAL - ¿Le gustaría instalar el tema sddm catppuccin? (s/n)" install_sddm_catppuccin
echo

if [[ $install_sddm_catppuccin =~ ^[Ss]$ ]]; then
    for sddm_theme in sddm-catppuccin-git; do
        install_package "$sddm_theme" 2>&1 | tee -a "$LOG"
        if [ $? -ne 0 ]; then
            echo -e "\e[1A\e[K${ERROR} - $sddm_theme la instalación ha fallado, verifique install.log."
            exit 1
        fi
    done	
    echo -e "[Theme]\nCurrent=catppuccin" | sudo tee -a "$sddm_conf_dir/10-theme.conf" 2>&1 | tee -a "$LOG"
else
    printf "SDDM no se instalará.\n"
fi
    
# Limpiar pantalla.
clear

# XDPH
printf "Tenga en cuenta que XDPH solo es necesario para screencast/screenshot. Hyprland seguirá funcionando, por lo tanto, esto es opcional.\n"
printf "\n"
read -n1 -rep "${CAT} ¿Le gustaría instalar XDG-Portal-Hyprland? (s/n)" XDPH
if [[ $XDPH =~ ^[Ss]$ ]]; then
    printf "Instalando XDPH...\n"
    for xdph in xdg-desktop-portal-hyprland; do
        install_package "$xdph" 2>&1 | tee -a "$LOG"
        if [ $? -ne 0 ]; then
            echo -e "\e[1A\e[K${ERROR} - $xdph la instalación ha fallado, verifique install.log."
            exit 1
        fi
    done
        
printf "Comprobación de otras implementaciones de XDG-Desktop-Portal...\n"
sleep 1
printf "\n"
printf "XDG-desktop-portal-KDE (si está instalado) debe desactivarse o eliminarse manualmente.\n"
read -n1 -rep "${CAT} ¿Quiere que intente eliminar otras implementaciones de XDG-Desktop-Portal? (s/n)" XDPH1
sleep 1
if [[ $XDPH1 =~ ^[Ss]$ ]]; then
    # Limpiar otros portales.
    printf "Borrando cualquier otra implementación de xdg-desktop-portal...\n"
    # Comprobar si los paquetes están instalados y desinstálar si están presentes.
    if pacman -Qs xdg-desktop-portal-gnome > /dev/null ; then
        echo "Eliminando xdg-desktop-portal-gnome..."
        sudo pacman -R --noconfirm xdg-desktop-portal-gnome 2>&1 | tee -a "$LOG"
    fi
    if pacman -Qs xdg-desktop-portal-gtk > /dev/null ; then
        echo "Eliminando xdg-desktop-portal-gtk..."
        sudo pacman -R --noconfirm xdg-desktop-portal-gtk 2>&1 | tee -a "$LOG"
    fi
    if pacman -Qs xdg-desktop-portal-wlr > /dev/null ; then
        echo "Eliminando xdg-desktop-portal-wlr..."
        sudo pacman -R --noconfirm xdg-desktop-portal-wlr 2>&1 | tee -a "$LOG"
    fi
    if pacman -Qs xdg-desktop-portal-lxqt > /dev/null ; then
        echo "Eliminando xdg-desktop-portal-lxqt..."
        sudo pacman -R --noconfirm xdg-desktop-portal-lxqt 2>&1 | tee -a "$LOG"
    fi    
    print_success "Todas las demás implementaciones de XDG-desktop-portal se borraron."
else
    printf "${NOTE} XDPH no se instalará...\n"
fi

# Limpiar pantalla.
clear

#-------------------------------------------------#
# Deshabilitar el modo de ahorro de energía wifi. #
#-------------------------------------------------#
read -n1 -rp "${CAT} ¿Te gustaría deshabilitar wifi powersave? (s/n) " WIFI
    if [[ $WIFI =~ ^[Ss]$ ]]; then
        LOC="/etc/NetworkManager/conf.d/wifi-powersave.conf"
        if [ -f "$LOC" ]; then
            printf "${OK} Parece que el ahorro de energía wifi ya está deshabilitado.\n"
            sleep 2
        else
            printf "\n"
            printf "${NOTE} Se ha añadido lo siguiente a $LOC.\n"
            printf "[connection]\nwifi.powersave = 2" | sudo tee -a $LOC
            printf "\n"
            printf "${NOTE} Reiniciando el servicio NetworkManager...\n"
            sudo systemctl restart NetworkManager 2>&1 | tee -a "$LOG"
            sleep 2        
        fi    
else
    printf "${NOTE} El modo de ahorro de energía wifi no se desactivó.\n"
fi

# Limpiar pantalla.
clear


# Función para detectar la distribución del teclado en un entorno tty.
detect_tty_layout() {
    layout=$(localectl status --no-pager | awk '/X11 Layout/ {print $3}')
    if [ -n "$layout" ]; then
        echo "$layout"
    else
        echo "desconocido"
    fi
}

# Preparando el diseño del teclado hyprland.conf
# Función para detectar la distribución del teclado en un entorno de servidor X.
detect_x_layout() {
    layout=$(setxkbmap -query | grep layout | awk '{print $2}')
    if [ -n "$layout" ]; then
        echo "$layout"
    else
        echo "desconocido"
    fi
}

# Detecta la disposición actual del teclado en función del entorno.
if [ -n "$DISPLAY" ]; then
    # El sistema está en un entorno de servidor X.
    layout=$(detect_x_layout)
else
# El sistema está en un entorno tty.
    layout=$(detect_tty_layout)
fi

echo "Keyboard layout: $layout"

printf "Detectando la distribución del teclado para preparar los cambios necesarios en hyprland.conf antes de copiar.\n"
printf "\n"
printf "\n"

# Pedir al usuario que confirme si el diseño detectado es correcto.
read -p "Diseño de teclado o mapa de teclas detectado: $layout. ¿Es esto correcto? [s/n] " confirm

if [ "$confirm" = "s" ]; then
    # Si el diseño detectado es correcto, actualizar la línea 'kb_layout=' en el archivo.
    awk -v layout="$layout" '/kb_layout/ {$0 = "  kb_layout=" layout} 1' ~/hypramigo/configs/hypr/hyprland.conf > temp.conf
    mv temp.conf ~/hypramigo/configs/hypr/hyprland.conf
else
    # Si el diseño detectado no es correcto, solicitar al usuario que ingrese el diseño correcto.
    printf "Asegúrese de escribir el diseño de teclado adecuado, por ejemplo, gb, de, pl, etc.\n"
    read -p "Ingrese el diseño de teclado correcto: " new_layout
    # Actualizar la línea 'kb_layout=' con el diseño correcto en el archivo.
    awk -v new_layout="$new_layout" '/kb_layout/ {$0 = "  kb_layout=" new_layout} 1' ~/hypramigo/configs/hypr/hyprland.conf > temp.conf
    mv temp.conf ~/hypramigo/configs/hypr/hyprland.conf
fi
    
# Limpiar pantalla.
clear

#-----------------------------------#
# Copiar archivos de configuración. #
#-----------------------------------#
read -n1 -rep "${CAT} ¿Le gustaría copiar archivos de configuración y fondos de pantalla? (s,n)" CFG
if [[ $CFG =~ ^[Ss]$ ]]; then
    printf " Copiando archivos de configuracion...\n"
    mkdir -p ~/.config
    cp -r ~/hypramigo/configs/hypr ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de hypr."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r ~/hypramigo/configs/kitty ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de kitty."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r ~/hypramigo/configs/dunst ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de dunst."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r ~/hypramigo/configs/rofi ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de rofi."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r ~/hypramigo/configs/scripts ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de scripts."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r ~/hypramigo/configs/swappy ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de swappy."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r ~/hypramigo/configs/swaylock ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de swaylock."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r ~/hypramigo/configs/waybar ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de waybar."; exit 1; } 2>&1 | tee -a "$LOG"
    chmod +x "$HOME/.config/waybar/scripts/mediaplayer.py" "$HOME/.config/waybar/scripts/wlrecord.sh"
    chmod +x ~/.config/waybar/scripts/playerctl/playerctl.sh
    printf "Zsh.........................."
    sudo usermod --shell /usr/bin/zsh $USER > /dev/null 2>&1
    sudo usermod --shell /usr/bin/zsh root > /dev/null 2>&1
    cp -r ~/hypramigo/configs/.zshrc $HOME/
    sudo ln -s -f ~/.zshrc /root/.zshrc
    echo -e "\e[32mOK\e[0m"
    mkdir -p ~/Imágenes
    cp -r ~/hypramigo/configs/loficafe.jpg ~/Imágenes/ && { echo "¡Copia completada!"; } || { echo "Error: no se pudieron copiar los fondos de pantalla"; exit 1; } 2>&1 | tee -a "$LOG"

    # Dar permisos de ejecucion al script. 
    chmod +x ~/.config/scripts/* 2>&1 | tee -a "$LOG"
else
    print_error "No se copiaron archivos de configuración ni archivos de fondo de pantalla."
fi


# Script terminado #
printf "Instalación completa."
printf "\n"
read -n1 -rep "${CAT} ¿Le gustaría reiniciar el sistema ahora? (s,n)" Rboot
if [[ $Rboot =~ ^[Ss]$ ]]; then
    sudo reboot 2>&1 | tee -a "$LOG"
else
    print_error "Regresando al simbolo del sistema..."
    exit
fi
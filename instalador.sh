#!/bin/bash
#
#-------------------------------------------------#
# Establecer colores para los mensajes de salida. #
#-------------------------------------------------#

OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
WARN="$(tput setaf 166)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
ORANGE=$(tput setaf 166)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)
GREN='\033[0;32m'

#---------------------------------------------------------------------------------------#
# Establecer el nombre del archivo de registro para incluir la fecha y la hora actuales #
#---------------------------------------------------------------------------------------#

LOG="install-$(date +%d-%H%M%S).log"

echo ""
echo "         #####################################################"
echo "         #                     BIENVENIDO!                   #"
echo "         #####################################################"
echo ""
printf "\n"

# Imprimir mensaje de advertencia de contraseña.
printf "\n${YELLOW} Algunos comandos requieren que ingrese su contraseña para poder ejecutarse.\n"
printf "Si le preocupa ingresar su contraseña, puede cancelar el script y revisar el contenido de este script.${RESET}\n"
sleep 2
printf "\n"
printf "\n"

# Continuar con la instalacion.
read -n1 -rep "${CAT} ¿Desea continuar con la instalación? (S/N) " PROCEED
    echo
if [[ $PROCEED =~ ^[Ss]$ ]]; then
    printf "\n%s  Iniciando la instalación...\n" "${OK}"
else
    printf "\n%s  No se realizaron cambios en tu sistema.\n" "${NOTE}"
    exit
fi

#clear screen
clear

#----------------------------------------------------------#
# Buscar el ayudante de AUR e instálar si no se encuentra. #
#----------------------------------------------------------#

printf "\n%s - Se necesita el programa Yay para instalar algunos paquetes desde AUR. Verificando si se encuentra instalado...\n" "${NOTE}"
sleep 2
ISAUR=$(command -v yay)

if [ -n "$ISAUR" ]; then
    printf "\n%s - El programa Yay ya está instalado. Continuando con la ejecución del script...\n" "${OK}"
    sleep 2
else 
    printf "\n%s - El programa Yay no se encuentra instalado.\n" "$WARN"
    printf "\n%s - Instalando yay desde AUR...\n" "${NOTE}"
                git clone https://aur.archlinux.org/yay-bin.git || { printf "%s - Error al clonar yay desde AUR.\n" "${ERROR}"; exit 1; }
                cd yay-bin || { printf "%s - Error al ingresar al directorio yay-bin.\n" "${ERROR}"; exit 1; }
                makepkg -si --noconfirm 2>&1 | tee -a "$LOG" || { printf "%s - Error al instalar yay desde AUR.\n" "${ERROR}"; exit 1; }
                cd ..
fi

# Limpiar pantalla.
clear

#------------------------#
# Actualizar el sistema. #
#------------------------#

printf "\n%s - Realizando una actualización completa del sistema para evitar problemas...\n" "${NOTE}"
sleep 2
ISAUR=$(command -v yay || command -v paru)

$ISAUR -Syu --noconfirm 2>&1 | tee -a "$LOG" || { printf "%s - No se pudo actualizar el sistema.\n" "${ERROR}"; exit 1; }

# Limpiar pantalla.
clear

#---------------------------------------------------#
# Configurar el script para salir en caso de error. #
#---------------------------------------------------#

set -e

#---------------------------------#
# Función para instalar paquetes. #
#---------------------------------#
install_package() {
    # Comprobando si el paquete ya está instalado.
    if $ISAUR -Q "$1" &>> /dev/null ; then
        echo -e "${OK} $1 Ya está instalado, saltando..."
    else
        # Paquete no instalado.
        echo -e "${NOTE} Instalando $1 ..."
        $ISAUR -S --noconfirm "$1" 2>&1 | tee -a "$LOG"
        # Asegurarse de que el paquete esté instalado.
        if $ISAUR -Q "$1" &>> /dev/null ; then
            echo -e "\e[1A\e[K${OK} $1 Fue instalado."
        else
            # Falta algo, saliendo para revisar el registro.
            echo -e "\e[1A\e[K${ERROR} $1 No se pudo instalar, verifique install.log. ¡Es posible que deba instalarlo manualmente!"
            exit 1
        fi
    fi
}

# Función para imprimir mensajes de error.
print_error() {
    printf " %s%s\n" "${ERROR}" "$1" "$NC" 2>&1 | tee -a "$LOG"
}

# Función para imprimir mensajes de éxito.
print_success() {
    printf "%s%s%s\n" "${OK}" "$1" "$NC" 2>&1 | tee -a "$LOG"
}

# Salir inmediatamente si un comando sale con un estado distinto de cero.
set -e

#----------------------------------------------------------------------------------------#
# Instalación de Hyprland, incluida la detección automática de Nvidia-GPU en su sistema. #
#----------------------------------------------------------------------------------------#

if ! lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
    printf "${YELLOW} No se detectó GPU NVIDIA en su sistema. Instalando Hyprland sin el soporte de Nvidia..."
    sleep 1
    for HYP in hyprland; do
        install_package "$HYP" 2>&1 | tee -a $LOG
    done
else
	# Solicitar al usuario la instalación de Nvidia.
	printf "${YELLOW} GPU NVIDIA detectada. Tenga en cuenta que nvidia-wayland sigue siendo inestable.\n"
	sleep 2
	read -n1 -rp "${CAT} ¿Te gustaría instalar Nvidia Hyprland? (s/n) " NVIDIA
	echo

	if [[ $NVIDIA =~ ^[Ss]$ ]]; then
    	# Instalar Nvidia Hyprland
    	printf "\n"
    	printf "${YELLOW}Instalando Nvidia Hyprland...${RESET}\n"
    	if pacman -Qs hyprland > /dev/null; then
        	read -n1 -rp "${CAT} Hyprland detectado. ¿Le gustaría eliminar e instalar hyprland-nvidia-git en su lugar? (s/n) " nvidia_hypr
        	echo
        	if [[ $nvidia_hypr =~ ^[Ss]$ ]]; then
            	sudo pacman -R --noconfirm hyprland 2>/dev/null | tee -a "$LOG" || true
        	fi
    		fi
    		for hyprnvi in hyprland hyprland-nvidia hyprland-nvidia-hidpi-git; do
        	sudo pacman -R --noconfirm "$hyprnvi" 2>/dev/null | tee -a $LOG || true
    		done
    	install_package "hyprland-nvidia-git" 2>&1 | tee -a $LOG
	else
    		printf "\n"
   	 	printf "${YELLOW} Instalando Hyprland sin compatibilidad con Nvidia...\n"
    		for hyprnvi in hyprland-nvidia-git hyprland-nvidia hyprland-nvidia-hidpi-git; do
        	sudo pacman -R --noconfirm "$hyprnvi" 2>/dev/null | tee -a $LOG || true
    		done
    		for HYP2 in hyprland; do
        install_package "$HYP2" 2>&1 | tee -a $LOG
    		done
	fi

    #---------------------------------------------------#
    # Instalar driver y paquetes adicionales de nvidia. #
    #---------------------------------------------------#

	printf "\n"
	printf "\n"
    printf "\n${NOTE} Tenga en cuenta nvidia-dkms solo es compatible con la serie GTX 900 y posteriores. Si ya tiene instalados los controladores nvidia, tal vez sea conveniente elegir no instalar.\n"  
	read -n1 -rp "${CAT} ¿Le gustaría instalar el controlador nvidia-dkms, nvidia-settings y nvidia-utils y todos los demás paquetes de nvidia? (s/n) " nvidia_driver
        echo
        	if [[ $nvidia_driver =~ ^[Ss]$ ]]; then
		printf "${YELLOW} Instalando paquetes de Nvidia...\n"
        		for krnl in $(cat /usr/lib/modules/*/pkgbase); do
            	for NVIDIA in "${krnl}-headers" nvidia-dkms nvidia-settings nvidia-utils libva libva-nvidia-driver-git; do
            	install_package "$NVIDIA" 2>&1 | tee -a $LOG
            	done
        	done
	else
    	printf "${NOTE} ¡No se instalaran paquetes de nvidia!\n"
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
            printf "${YELLOW} Agregando opciones a $NVEA..."
            sudo echo -e "options nvidia-drm modeset=1" | sudo tee -a /etc/modprobe.d/nvidia.conf 2>&1 | tee -a $LOG
            printf "\n"  
            fi
    
	# Lista negra nouveau.
	read -n1 -rep "${CAT} ¿Le gustaría incluir a nouveau en la lista negra? (s/n)" response
	echo
	if [[ $response =~ ^[Ss]$ ]]; then
    	NOUVEAU="/etc/modprobe.d/nouveau.conf"
    	if [ -f "$NOUVEAU" ]; then
        	printf "${OK} Parece que nouveau ya está en la lista negra.\n"
    	else
        	printf "\n"
        	echo "blacklist nouveau" | sudo tee -a "$NOUVEAU" 2>&1 | tee -a $LOG 
        	printf "${NOTE} Ha sido agregado a $NOUVEAU.\n"
        	printf "\n"          

        	# A la lista negra completamente nouveau.
        	if [ -f "/etc/modprobe.d/blacklist.conf" ]; then
            	echo "install nouveau /bin/true" | sudo tee -a "/etc/modprobe.d/blacklist.conf" 2>&1 | tee -a $LOG 
        	else
            	echo "install nouveau /bin/true" | sudo tee "/etc/modprobe.d/blacklist.conf" 2>&1 | tee -a $LOG 
        	fi
    	fi
	else
    	printf "${NOTE} Saltarse la lista negra de nouveau.\n"
	fi

fi

# Limpiar pantalla.
clear 

# Instalación de otros componentes necesarios.
printf "\n%s - Instalando otros componentes necesarios...\n" "${NOTE}"
sleep 2

for PKG1 in foot swaybg swaylock-effects wofi wlogout dunst grim slurp wl-clipboard cliphist swappy polkit-kde-agent nwg-look-bin swww mousepad pipewire-alsa playerctl; do
    install_package "$PKG1" 2>&1 | tee -a "$LOG"
    if [ $? -ne 0 ]; then
        echo -e "\e[1A\e[K${ERROR} - $PKG1 la instalación ha fallado, verifique install.log"
        exit 1
    fi
done

for PKG2 in qt5ct btop jq gvfs gvfs-mtp ffmpegthumbs mpv python-requests pamixer brightnessctl xdg-user-dirs viewnior network-manager-applet micro cava pavucontrol; do
    install_package  "$PKG2" 2>&1 | tee -a "$LOG"
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

#-------------------#
#       Temas       #
#-------------------#
printf "\n${NOTE} ¡SE NECESITAN TEMAS GTK PARA LA TRANSICIÓN DARK-LIGHT! Instalando temas...\n"
for THEME in catppuccin-gtk-theme-mocha catppuccin-gtk-theme-latte catppuccin-cursors-mocha gtk-engine-murrine; do
    install_package "$THEME" 2>&1 | tee -a "$LOG"
    if [ $? -ne 0 ]; then
        echo -e "\e[1A\e[K${ERROR} - $THEME la instalación ha fallado, verifique install.log"
        exit 1
    fi
done

#-------------------------------------------------------#
# Comprobar si está instalado waybar o waybar-hyprland. #
#-------------------------------------------------------#

if pacman -Qs waybar > /dev/null; then
    read -n1 -rep "${CAT} Waybar ya está instalada. ¿Le gustaría desinstalarla e instalar waybar-hyprland-git? (s/n)" bar
    echo
    if [[ $bar =~ ^[Ss]$ ]]; then
        sudo pacman -R --noconfirm waybar 2>> "$LOG" > /dev/null || true
        sudo pacman -R --noconfirm waybar-hyprland 2>> "$LOG" > /dev/null || true
        install_package waybar-hyprland-git 2>&1 | tee -a "$LOG"
        if [ $? -ne 0 ]; then
            echo -e "\e[1A\e[K${ERROR} - La instalación de waybar-hyprland-git ha fallado, verifique install.log"
            exit 1
        fi
    else
        echo "Decidiste no instalar waybar-hyprland-git."
    fi
else
    install_package waybar-hyprland-git 2>&1 | tee -a "$LOG"
    if [ $? -ne 0 ]; then
        echo -e "\e[1A\e[K${ERROR} - La instalación de waybar-hyprland-git ha fallado, verifique install.log"
        exit 1
    fi
fi

echo
print_success "Todos los paquetes necesarios han sido instalados con éxito."
sleep 2

# Limpiar pantalla.
clear

#---------------------------------------------------#
#           Administrador de archivos.              #
#---------------------------------------------------#

read -n1 -rep "${CAT} - ¿Le gustaría instalar Thunar como administrador de archivos? (s/n)" inst3
echo

if [[ $inst3 =~ ^[Ss]$ ]]; then
  for THUNAR in thunar thunar-volman tumbler thunar-archive-plugin; do
    install_package "$THUNAR" 2>&1 | tee -a "$LOG"
        if [ $? -ne 0 ]; then
        echo -e "\e[1A\e[K${ERROR} - $THUNAR la instalación ha fallado, verifique install.log"
        exit 1
    fi
    done

    # Verificar las carpetas de configuración existentes y la copia de seguridad.
    for DIR1 in Thunar xfce4; do 
        DIRPATH=~/.config/$DIR1
        if [ -d "$DIRPATH" ]; then 
            echo -e "${NOTE}  Config para $DIR1 encontrada, haciendo respaldo."
            mv $DIRPATH $DIRPATH-back-up 2>&1 | tee -a "$LOG"
            echo -e "${NOTE}  Guardado $DIR1 en $DIRPATH-back-up."
        fi
    done
    cp -r config/xfce4 ~/.config/ && { echo "¡Copia de xfce4 completada!"; } || { echo "Error: no se pudieron copiar los archivos de configuración de xfce4."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r config/Thunar ~/.config/ && { echo "¡Copia de Thunar completada!"; } || { echo "Error: no se pudieron copiar los archivos de configuración de Thunar."; exit 1; } 2>&1 | tee -a "$LOG"
else
  printf "${NOTE} Thunar no se instalará.\n"
fi

# Limpiar pantalla.
clear

#------------------#
#     BLUETOOTH    #
#------------------#
read -n1 -rep "${CAT} OPCIONAL - ¿Le gustaría instalar paquetes de Bluetooth? (s/n)" inst4
if [[ $inst4 =~ ^[Ss]$ ]]; then
  printf "${NOTE} Instalando paquetes de Bluetooth...\n"
  for BLUE in bluez bluez-utils blueman; do
    install_package "$BLUE" 2>&1 | tee -a "$LOG"
         if [ $? -ne 0 ]; then
        echo -e "\e[1A\e[K${ERROR} - $BLUE la instalación ha fallado, verifique install.log"
        exit 1
        fi
    done

  printf " Activando servicios Bluetooth...\n"
  sudo systemctl enable --now bluetooth.service 2>&1 | tee -a "$LOG"
else
  printf "${NOTE} No hay paquetes de bluetooth instalados...\n"
fi

# Limpiar pantalla.
clear

#-----------------------------------#
# Instalar SDDM y Catppuccin theme. #
#-----------------------------------#
read -n1 -rep "${CAT} - ¿Le gustaría instalar SDDM como administrador de inicio de sesión? (s/n)" install_sddm
echo

if [[ $install_sddm =~ ^[Ss]$ ]]; then
  # Comprobar si SDDM ya está instalado.
  if pacman -Qs sddm > /dev/null; then
    # Prompt user to manually install sddm-git to remove SDDM
    read -n1 -rep "SDDM ya está instalado. ¿Le gustaría instalar manualmente sddm-git para eliminarlo? Esto requiere una intervención manual. (s/n)" manual_install_sddm
    echo
    if [[ $manual_install_sddm =~ ^[Ss]$ ]]; then
      $ISAUR -S sddm-git 2>&1 | tee -a "$LOG"
    fi
  fi
  
  printf "${NOTE} Instalación de SDDM-git...\n"
  for package in sddm-git; do
    install_package "$package" 2>&1 | tee -a "$LOG"
    if [ $? -ne 0 ]; then
      echo -e "\e[1A\e[K${ERROR} - $package la instalación ha fallado, verifique install.log"
      exit 1
    fi
   done 

    # Verifique si otros administradores de inicio de sesión instalaron y deshabilitaron su servicio antes de habilitar sddm.
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
    echo -e "${NOTE} Configuración de la pantalla de inicio de sesión."
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
          echo -e "\e[1A\e[K${ERROR} - $sddm_theme la instalación ha fallado, verifique install.log"
          exit 1
    	  fi
          done
    fi	
    echo -e "[Theme]\nCurrent=catppuccin" | sudo tee -a "$sddm_conf_dir/10-theme.conf" 2>&1 | tee -a "$LOG"
else
  printf "${NOTE} SDDM no se instalará.\n"
fi
 
# Limpiar pantalla.
clear

#--------#
#  XDPH  #
#--------#
printf "${YELLOW} Tenga en cuenta que XDPH solo es necesario para screencast/screenshot. Hyprland seguirá funcionando, por lo tanto, esto es opcional\n"
printf "\n"
read -n1 -rep "${CAT} ¿Le gustaría instalar XDG-Portal-Hyprland? (s/n)" XDPH
if [[ $XDPH =~ ^[Ss]$ ]]; then
  printf "${NOTE} Instalando XDPH...\n"
  for xdph in xdg-desktop-portal-hyprland; do
    install_package "$xdph" 2>&1 | tee -a "$LOG"
        if [ $? -ne 0 ]; then
        echo -e "\e[1A\e[K${ERROR} - $xdph la instalación ha fallado, verifique install.log"
        exit 1
        fi
    done
    
    printf "${NOTE} Comprobación de otras implementaciones de XDG-Desktop-Portal...\n"
    sleep 1
    printf "\n"
    printf "${NOTE} XDG-desktop-portal-KDE (si está instalado) debe desactivarse o eliminarse manualmente.\n"
    read -n1 -rep "${CAT} ¿Quiere que intente eliminar otras implementaciones de XDG-Desktop-Portal? (s/n)" XDPH1
    sleep 1
    if [[ $XDPH1 =~ ^[Ss]$ ]]; then
        # Limpiar otros portales.
    printf "${NOTE} Borrando cualquier otra implementación de xdg-desktop-portal...\n"
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
    fi
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

#---------------------------------------------------------------------#
# Función para detectar la distribución del teclado en un entorno tty.#
#---------------------------------------------------------------------#
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

printf "${NOTE} Detectando la distribución del teclado para preparar los cambios necesarios en hyprland.conf antes de copiar.\n"
printf "\n"

# Pedir al usuario que confirme si el diseño detectado es correcto.
read -p "Diseño de teclado o mapa de teclas detectado: $layout. ¿Es esto correcto? [s/n] " confirm

if [ "$confirm" = "s" ]; then
  # Si el diseño detectado es correcto, actualizar la línea 'kb_layout=' en el archivo.
  awk -v layout="$layout" '/kb_layout/ {$0 = "  kb_layout=" layout} 1' config/hypr/hyprland.conf > temp.conf
  mv temp.conf config/hypr/hyprland.conf
else
  # Si el diseño detectado no es correcto, solicitar al usuario que ingrese el diseño correcto.
  printf "${WARN} Asegúrese de escribir el diseño de teclado adecuado, por ejemplo, gb, de, pl, etc.\n"
  read -p "Ingrese el diseño de teclado correcto: " new_layout
  # Actualizar la línea 'kb_layout=' con el diseño correcto en el archivo.
  awk -v new_layout="$new_layout" '/kb_layout/ {$0 = "  kb_layout=" new_layout} 1' config/hypr/hyprland.conf > temp.conf
  mv temp.conf config/hypr/hyprland.conf
fi
printf "\n"

# Limpiar pantalla.
clear

#-----------------------------------#
# Copiar archivos de configuración. #
#-----------------------------------#

set -e # Salir inmediatamente si un comando sale con un estado distinto de cero.

read -n1 -rep "${CAT} ¿Le gustaría copiar archivos de configuración y fondos de pantalla? (s,n)" CFG
if [[ $CFG =~ ^[Ss]$ ]]; then

# Verificar las carpetas de configuración existentes y hacer copia de seguridad. 
    for DIR in btop cava foot hypr dunst swappy swaylock waybar wlogout wofi 
    do 
        DIRPATH=~/.config/$DIR
        if [ -d "$DIRPATH" ]; then 
            echo -e "${NOTE} - Configuración para $DIR encontrada, intentando hacer una copia de seguridad."
            mv $DIRPATH $DIRPATH-back-up 2>&1 | tee -a "$LOG"
            echo -e "${NOTE} - Backed up $DIR to $DIRPATH-back-up."
        fi

    done

    for DIRw in Wallpapers
    do 
        DIRPATH=~/Imágenes/$DIRw
        if [ -d "$DIRPATH" ]; then 
            echo -e "${NOTE} - Wallpapers en $DIRw encontrados, intentando hacer una copia de seguridad."
            mv $DIRPATH $DIRPATH-back-up 2>&1 | tee -a "$LOG"
            echo -e "${NOTE} - Guardados $DIRw en $DIRPATH-back-up."
        fi

    done

    printf " Copiando archivos de configuracion...\n"
    mkdir -p ~/.config
    cp -r config/hypr ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de hypr."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r config/nwg-look ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de hypr."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r config/swaylock ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de hypr."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r config/wofi ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de hypr."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r config/foot ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de foot."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r config/dunst ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de dunst."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r config/wlogout ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de wlogout."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r config/btop ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de btop."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r config/cava ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de cava."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -r config/swappy ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de swappy."; exit 1; } 2>&1 | tee -a "$LOG"
    mkdir -p ~/Imágenes/Wallpapers
    cp -r cosas/Wallpapers ~/Imágenes/ && { echo "¡Copia completada!"; } || { echo "Error: no se pudieron copiar los fondos de pantalla"; exit 1; } 2>&1 | tee -a "$LOG"
    cd ~/hypramigo
    cp -r config/waybar ~/.config/ || { echo "Error: no se pudieron copiar los archivos de configuración de waybar."; exit 1; } 2>&1 | tee -a "$LOG"
    cp -f 'config/waybar/style/dark-styles/style-dark-cat.css' 'config/waybar/style/style-dark.css'
    
    # Shiny-Dark-Icons-themes
    mkdir -p ~/.icons
    cd cosas/iconos
    tar -xf Shiny-Dark-Icons.tar.gz -C ~/.icons
    tar -xf Shiny-Light-Icons.tar.gz -C ~/.icons
    #tar -xf Win11icons.tar.gz -C ~/.icons

    # Dar permisos de ejecucion al script. 
    chmod +x ~/.config/hypr/scripts/* 2>&1 | tee -a "$LOG"
else
   print_error "No se copiaron archivos de configuración ni archivos de fondo de pantalla."
fi

#Limpiar pantalla.
clear

# Script terminado #
printf "\n${OK} Instalación completa.\n"
printf "\n"
read -n1 -rep "${CAT} ¿Le gustaría reiniciar el sistema ahora? (s,n)" Rboot
if [[ $Rboot =~ ^[Ss]$ ]]; then
    sudo reboot 2>&1 | tee -a "$LOG"
    
else
    print_error "Regresando al simbolo del sistema...\n"
fi
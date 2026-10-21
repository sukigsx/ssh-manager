#!/usr/bin/env bash

#VARIABLES PRINCIPALES
# con export son las variables necesarias para exportar al los siguientes script
#variables para el menu_info

export NombreScript="ssh-Manager"
export DescripcionDelScript="PRUEBA DE MEJORA"
export Correo="scripts@mbbsistemas.es"
export Web="https://repositorio.mbbsistemas.es"
export version="1.0"
conexion="Sin comprobar"
software="Sin comprobar"
actualizado="Sin comprobar"
paqueteria="No detectada"

# VARIABLE QUE RECOJEN LAS RUTAS
ruta_ejecucion=$(dirname "$(readlink -f "$0")") #es la ruta de ejecucion del script sin la / al final
ruta_escritorio=$(xdg-user-dir DESKTOP) #es la ruta de tu escritorio sin la / al final

# VARIABLES PARA LA ACTUALIZAION CON GITHUB
NombreScriptActualizar="ssh-manager.sh" #contiene el nombre del script para poder actualizar desde github
DireccionGithub="https://github.com/sukigsx/ssh-manager" #contiene la direccion de github para actualizar el script
nombre_carpeta_repositorio="ssh-manager" #poner el nombre de la carpeta cuando se clona el repo para poder eliminarla

# VARIABLES DE SOFTWARE NECESARIO
# Asociamos comandos con los paquetes correspondientes.
# Formato si cambian: [comando]="paquete_debian / paquete_redhat / paquete_arch"
# Formato si son iguales: [comando]="paquete_unico"
declare -A requeridos
requeridos=(
    # Requeridos para poder actualizar
        [git]="git/git/git"
        [diff]="diffutils/diffutils/diffutils"
        [sudo]="sudo/sudo/sudo"
        [ping]="iputils-ping/iputils/iputils/"
        [xdg-user-dir]="xdg-user-dirs/xdg-user-dirs/xdg-user-dirs"

    # Requeridos para el script en si
        [which]="which/which/which"
        [fzf]="fzf/fzf/fzf"
        [curl]="curl/curl/curl"
        [jq]="jq/jq/jq"
        [nc]="netcat-openbsd/nc/openbsd-netcat"
        [ssh-copy-id]="openssh-client/openssh-clients/openssh"
        [ssh-keygen]="openssh-client/openssh-clients/openssh"
        [awk]="gawk/gawk/gawk"
        [sed]="sed/sed/sed"


)
###########################
## FUNCIONES PRINCIPALES ##
###########################
#colores
rojo="\e[0;31m\033[1m" #rojo
verde="\e[;32m\033[1m"
azul="\e[0;34m\033[1m"
amarillo="\e[0;33m\033[1m"
rosa="\e[0;35m\033[1m"
turquesa="\e[0;36m\033[1m"
borra_colores="\033[0m\e[0m" #borra colores

#toma el control al pulsar control + c
trap ctrl_c INT
function ctrl_c()
{
clear
echo ""
echo -e "${azul} GRACIAS POR UTILIZAR MI SCRIPT${borra_colores}"
echo ""
sleep 1
exit
}

menu_info(){
# muestra el menu de sukigsx
echo ""
echo -e "${rosa}            _    _                  ${azul}   Nombre del script${borra_colores} $NombreScript"
echo -e "${rosa}  ___ _   _| | _(_) __ _ _____  __  ${azul}   Descripcion${borra_colores} $DescripcionDelScript"
echo -e "${rosa} / __| | | | |/ / |/ _\ / __\ \/ /  ${azul}   Version            =${borra_colores} $version"
echo -e "${rosa} \__ \ |_| |   <| | (_| \__ \>  <   ${azul}   Conexion Internet  =${borra_colores} $conexion"
echo -e "${rosa} |___/\__,_|_|\_\_|\__, |___/_/\_\  ${azul}   Software necesario =${borra_colores} $software"
echo -e "${rosa}                  |___/             ${azul}   Actualizado        =${borra_colores} $actualizado"
echo -e "${rosa}                                    ${azul}   Sistema paqueteria =${borra_colores} $paqueteria"
echo -e ""
echo -e "${azul} Contacto:${borra_colores} ( Correo${rosa} $Correo${borra_colores} ) ( Web${rosa} $Web${borra_colores} )${borra_colores}"
echo ""
}

#comprobar si hay actualizaciones y que lo marque en el menu_info y tambien pregunta si quieres actualizar
comprobar_actualizaciones(){

    git clone $DireccionGithub /tmp/comprobar >/dev/null 2>&1
    diff $ruta_ejecucion/$NombreScriptActualizar /tmp/comprobar/$NombreScriptActualizar >/dev/null 2>&1

    if [ $? = 0 ]
    then
        #esta actualizado, solo lo comprueba
        actualizado="SI"
        chmod -R +w /tmp/comprobar
        rm -R /tmp/comprobar
    else
        #hay que actualizar, comprueba y actualiza
        echo ""
        echo -e "${amarillo} Existe una actualizacion del script${borra_colores}"
        read -p " Quieres actualizar ? (S/n): " sino
        if [[ $sino == [sS] ]]; then
            actualizar_script
        else
            actualizado="NO"
        fi
        chmod -R +w /tmp/comprobar
        rm -R /tmp/comprobar
    fi
}

#funcion para actualizar el script
actualizar_script(){
    git clone $DireccionGithub /tmp/comprobar >/dev/null 2>&1

    cp -r /tmp/comprobar/* $ruta_ejecucion
    chmod -R +w /tmp/comprobar
    rm -R /tmp/comprobar
    echo ""
    echo -e "${amarillo} Sera necesario ejecutarlo de nuevo.${borra_colores}"

    printf " Actualizando... "
    for i in {1..20}; do
        printf "#"
        sleep 0.1
    done
    printf " [ \e[32mOK\e[0m ]\n"

    echo ""
    sleep 1
    exit
}

# Funcion para comprobar el software necesario
software_necesario(){
    # Detectamos la paqueteria y establecemos el idx_distro antes de evaluar la matriz
    paqueteria

    echo ""
    echo -e "${azul} Comprobando el software necesario.${borra_colores}"
    echo ""

    for comando in "${!requeridos[@]}"; do
        # Evaluamos si el valor de la matriz contiene variantes por barra '/'
        if [[ "${requeridos[$comando]}" == *"/"* ]]; then
            paquete_real=$(echo "${requeridos[$comando]}" | cut -d'/' -f$idx_distro)
        else
            paquete_real="${requeridos[$comando]}"
        fi

        command -v "$comando" &>/dev/null
        sino=$?
        contador=1
        while [ $sino -ne 0 ]; do
            if [ $contador -ge 4 ] || [ "$conexion" = "no" ]; then
                clear
                menu_info
                echo -e " ${amarillo}NO se puede ejecutar el script sin los paquetes necesarios ${rojo}$paquete_real${amarillo}.${borra_colores}"
                echo -e " ${amarillo}NO se ha podido instalar ${rojo}$paquete_real${amarillo}.${borra_colores}"
                echo -e " ${amarillo}Inténtelo usted con: (${borra_colores}$instalar $paquete_real${amarillo})${borra_colores}"
                echo ""
                echo -e "${azul} Listado de los paquetes necesarios para poder ejecutar el script:${borra_colores}"

                # Listar los nombres traducidos de los paquetes para comodidad del usuario
                for cmd_lista in "${!requeridos[@]}"; do
                    if [[ "${requeridos[$cmd_lista]}" == *"/"* ]]; then
                        echo -e "     $(echo "${requeridos[$cmd_lista]}" | cut -d'/' -f$idx_distro)"
                    else
                        echo -e "     ${requeridos[$cmd_lista]}"
                    fi
                done

                echo ""
                echo -e " ${rojo}No se puede ejecutar el script sin todo el software necesario.${borra_colores}"
                echo ""
                exit 1
            else
                echo -e "${amarillo} Se necesita instalar ${borra_colores}$comando${amarillo} para la ejecucion del script${borra_colores}"
                echo " Instalando $paquete_real. Intento $contador/3."

                # Ejecución de la instalación silenciosa
                $instalar "$paquete_real" &>/dev/null

                let "contador=contador+1"
                command -v "$comando" &>/dev/null
                sino=$?
            fi
        done
        echo -e " [${verde}ok${borra_colores}] $comando ($paquete_real)."
    done

    echo ""
    echo -e "${azul} Todo el software ${verde}OK${borra_colores}"
    software="SI"
}

# Función que comprueba si se ejecuta como root
check_root() {
    #clear
    #menu_info
  if [ "$EUID" -ne 0 ]; then
    #echo ""
    #echo -e "${amarillo} Se necesita privilegios de root ingresa la contraseña.${borra_colores}"

    # Pedir contraseña para sudo
    #echo -e ""

    # Validar contraseña mediante sudo -v (verifica sin ejecutar comando)
    if sudo -v; then
      echo ""
      echo -e "${verde} Autenticación correcta. Ejecutando como root...${borra_colores}"; sleep 2
      # Reejecuta el script como root
      #exec sudo "$0" "$@"
    else
      clear
      menu_info
      echo -e "${rojo} Contraseña incorrecta o acceso denegado. Saliendo del script.${borra_colores}"
      echo ""
      echo -e "${azul} Listado de los paquetes necesarios para poder ejecutar el script:${borra_colores}"
      for elemento in "${requeridos[@]}"; do
        echo -e "     $elemento"
      done
      echo ""
      echo -e "${azul} GRACIAS POR UTILIZAR MI SCRIPT${borra_colores}"
     echo ""; exit
    fi
  fi
}

# Funcion de detectar sistema de paquetado para instalar
paqueteria(){
    echo ""
    echo -e "${azul} Detectando sistema de paquetería...${borra_colores}"
    echo ""

    if command -v apt >/dev/null 2>&1; then
        echo -e "${verde} Sistema de paquetería detectado: APT (Debian, Ubuntu, Mint, etc.)${borra_colores}"
        instalar="sudo apt install -y"
        paqueteria="apt"
        idx_distro=1

    elif command -v dnf >/dev/null 2>&1; then
        echo -e "${verde} Sistema de paquetería detectado: DNF (Fedora, RHEL, Rocky, AlmaLinux)${borra_colores}"
        instalar="sudo dnf install -y"
        paqueteria="dnf"
        idx_distro=2

    elif command -v pacman >/dev/null 2>&1; then
        echo -e "${verde} Sistema de paquetería detectado: PACMAN (Arch Linux, Manjaro)${borra_colores}"
        instalar="sudo pacman -S --noconfirm"
        paqueteria="pacman"
        idx_distro=3

    else
        echo -e "${rojo} Sistema de paquetería no soportado automáticamente.${borra_colores}"
        paqueteria="No detectada"
        exit 1
    fi
}


#comprobar si se ejecuta en una terminal bash
terminal_bash() {

    shell_actual="$(ps -p $$ -o comm=)"

    if [ "$shell_actual" != "bash" ]; then
        echo -e "${amarillo} Este script ${rojo}NO${amarillo} se está ejecutando en Bash.${borra_colores}"
        echo -e "   Shell detectado: ${rojo}$shell_actual${borra_colores}"
        echo -e "   Puede ocasionar problemas ya que solo está pensado para bash."
        echo -e "   ${rojo}No${borra_colores} se procede con la instalación ni la ejecución."
        echo ""
        echo -e "${azul} GRACIAS POR UTILIZAR MI SCRIPT${borra_colores}"
        echo ""
        exit 1
    fi
}

conexion(){
#funcion de comprobar conexion a internet
#para que funciones necesita:
#   conexion ainternet
#   la paleta de colores
#   software: ping

if ping -c1 -W1 8.8.8.8 &>/dev/null
then
    conexion="SI"
    echo ""
    echo -e " Conexion a internet = ${verde}SI${borra_colores}"
else
    conexion="NO"
    echo ""
    echo -e " Conexion a internet = ${rojo}NO${borra_colores}"
fi
}

#logica de inicio
clear
menu_info
conexion
if [ $conexion = "SI" ]; then
    comprobar_actualizaciones
    if [ $actualizado = "SI" ]; then
        terminal_bash
        software_necesario
        if [ "$software" = "SI" ]; then
            export software="SI"
            export conexion="SI"
            export actualizado="SI"
            #bash $ruta_ejecucion/ #PON LA RUTA
        else
            echo ""
        fi
    else
        terminal_bash
        software_necesario
        if [ $software = "SI" ]; then
            export software="SI"
            export conexion="SI"
            export actualizado="NOOOOO"
            #bash $ruta_ejecucion/ #PON LA RUTA
        else
            echo ""
        fi
    fi
else
    software_necesario
    if [ $software = "SI" ]; then
        export software="SI"
        export conexion="NO"
        export actualizado="No se ha podido comprobar la actualizacion del script"
        #bash $ruta_ejecucion/ #PON LA RUTA
    else
        echo ""
    fi
fi

sleep 2
clear
menu_info


## Empieza lo gordo
# Directorio de claves SSH. Se recomienda que sea una ruta absoluta.
SSH_DIR="/home/$(whoami)/ssh_clientes"
KNOWN_HOSTS_FILE="$HOME/.ssh/known_hosts"

# Asegura que el directorio de claves exista
mkdir -p "$SSH_DIR"

# Detecta el emulador de terminal disponible
function find_terminal() {
    if command -v gnome-terminal &> /dev/null; then
        echo "gnome-terminal"
    elif command -v konsole &> /dev/null; then
        echo "konsole"
    elif command -v xfce4-terminal &> /dev/null; then
        echo "xfce4-terminal"
    elif command -v xterm &> /dev/null; then
        echo "xterm"
    elif command -v terminator &> /dev/null; then
        echo "terminator"
    else
        echo "none"
    fi
}

TERMINAL=$(find_terminal)

# Función para ejecutar el comando en la terminal adecuada
function run_in_terminal() {
    local title="$1"
    local command="$2"

    case "$TERMINAL" in
        "gnome-terminal")
            gnome-terminal --title="$title" -- bash -c "$command; exec bash" &
            ;;
        "konsole")
            konsole --new-tab -p tabtitle="$title" -e bash -c "$command; exec bash" &
            ;;
        "xfce4-terminal")
            xfce4-terminal --title="$title" -H -e "bash -c \"$command; exec bash\"" &
            ;;
        "xterm")
            xterm -T "$title" -e "bash -c \"$command; exec bash\"" &
            ;;
        "terminator")
            terminator -e "bash -c \"$command; exec bash\"" &
            ;;
        *)
            echo "Error: No se encontró un emulador de terminal compatible."
            return 1
            ;;
    esac
}

# Función para agregar un nuevo cliente
add_client() {
    clear
    echo ""
    read -p "Ingresa un nombre para el servidor ssh: " DISPLAY_NAME
    read -p "Ingresa el nombre de usuario del servidor $DISPLAY_NAME: " USERNAME
    read -p "Ingresa la dirección IP o el nombre de host del servidor $DISPLAY_NAME: " HOST
    echo ""

    # Comprobar si el puerto 22 está abierto
    if nc -z -w3 "$HOST" 22 > /dev/null 2>&1; then
        echo -e "${verde}El servidor${borra_colores} $DISPLAY_NAME ${verde}esta levantado.${borra_colores}"
    else
        echo -e "${rojo}No se pudo conectar al servidor${borra_colores} $DISPLAY_NAME${rojo}. \nVerifica que el servidor está encendido y accesible.${borra_colores}"
        sleep 5
        return
    fi

    # Crea un nombre de directorio único combinando usuario y host
    CLIENT_DIR="$SSH_DIR/${USERNAME}_${HOST//./-}"
    mkdir -p "$CLIENT_DIR"

    echo ""
    echo -e "${azul}Generando par de claves SSH para:"
    echo -e "${azul}Servidor =${borra_colores} $DISPLAY_NAME"
    echo -e "${azul}Usuario  =${borra_colores} $USERNAME"
    echo -e "${azul}Host     =${borra_colores} $HOST"

    echo ""
    ssh-keygen -t rsa -b 4096 -f "$CLIENT_DIR/id_rsa" -N ""

    echo ""
    echo -e "${azul}Copiando la clave pública al servidor...${borra_colores}"
    ssh-copy-id -i "$CLIENT_DIR/id_rsa.pub" "$USERNAME@$HOST"

    # Ahora guardamos el nombre a mostrar, el usuario y el host
    echo "$DISPLAY_NAME,$USERNAME,$HOST" >> "$SSH_DIR/clientes.txt"
    echo ""
    echo -e "${verde}¡Cliente '$DISPLAY_NAME' agregado exitosamente!${borra_colores}"; sleep 3
}

# Función para conectarse a uno o varios clientes usando fzf
connect_client() {
    clear
    echo ""
    if [ ! -f "$SSH_DIR/clientes.txt" ]; then
        clear
        echo -e "${rojo}No hay servidores registrados.${borra_colores}"; sleep 3
        return
    fi

    # Muestra el nombre a mostrar en el menú
    CLIENTS=$(cat "$SSH_DIR/clientes.txt" | awk -F',' '{print $1" ("$2"@" $3")"}' | fzf -m --layout=reverse --prompt="Selecciona uno o más servidores (Tab para seleccionar, Enter para confirmar, Esc para regresar): ")

    if [[ -n "$CLIENTS" ]]; then
        echo -e "${azul}Verificando estado de servidores...${borra_colores}"; echo ""
        # Extrae la información del formato 'Nombre (usuario@host)'
        echo "$CLIENTS" | while read -r CLIENT; do
            USERNAME=$(echo "$CLIENT" | sed -E 's/.* \((.*)@.*/\1/')
            HOST=$(echo "$CLIENT" | sed -E 's/.*@(.*)\)/\1/')
            DISPLAY_NAME=$(echo "$CLIENT" | sed -E 's/ (.*)//')

            #Crea un nombre de directorio único para la conexión
            CLIENT_DIR_UNIQUE="${USERNAME}_${HOST//./-}"

            # 🔎 Comprobar si el puerto 22 está abierto
            if nc -z -w3 "$HOST" 22; then
                echo -e "${verde}Conectando a ${borra_colores}'$DISPLAY_NAME' ($USERNAME@$HOST)${verde} en nueva ventana terminal.${borra_colores}"; #sleep 2

                run_in_terminal "$DISPLAY_NAME ($USERNAME@$HOST)" "ssh -X -i \"$SSH_DIR/$CLIENT_DIR_UNIQUE/id_rsa\" \"$USERNAME@$HOST\"" > /dev/null 2>&1
            else
                DISPLAY_NAME=$(echo "$CLIENT" | sed -E 's/ (.*)//')
                echo -e "${rojo}No se pudo conectar a${borra_colores} $DISPLAY_NAME${rojo}. Saltando conexion.${borra_colores}"
                #sleep 2
            fi
        done
        sleep 5
    else
        echo -e "${verde}Regresando al menu principal.${borra_colores}"
    fi
    sleep 2
    #ctrl_c
}

# Función para revocar el acceso a un cliente
revoke_access() {
    clear
    echo ""
    if [ ! -f "$SSH_DIR/clientes.txt" ]; then
        echo -e "${rojo}No hay clientes registrados.${borra_colores}"
        return
    fi

    CLIENT_REVOKE=$(cat "$SSH_DIR/clientes.txt" | awk -F',' '{print $1" ("$2"@" $3")"}' | fzf --layout=reverse --prompt="Selecciona un servidor para revocar el acceso (Esc para regresar):")


    if [[ -n "$CLIENT_REVOKE" ]]; then
        echo -e "${azul}Verificando estado de servidores...${borra_colores}"; echo ""
        # Extrae la información del formato 'Nombre (usuario@host)'
        USERNAME=$(echo "$CLIENT_REVOKE" | sed -E 's/.* \((.*)@.*/\1/')
        HOST=$(echo "$CLIENT_REVOKE" | sed -E 's/.*@(.*)\)/\1/')
        DISPLAY_NAME=$(echo "$CLIENT_REVOKE" | sed -E 's/ (.*)//')

        # Crea un nombre de directorio único para la revocación
        CLIENT_DIR_UNIQUE="${USERNAME}_${HOST//./-}"

        # 🔎 Comprobar si el puerto 22 está abierto

        if nc -z -w3 "$HOST" 22; then
            echo -e "${amarillo}Revocando acceso del servidor${borra_colores} $DISPLAY_NAME ${amarillo}del${borra_colores} $USERNAME@$HOST"; sleep 2

            #comprueba si el usuario tiene sudo o no
            ssh "$USERNAME@$HOST" 'sudo -l' > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                # Eliminar clave del archivo authorized_keys en el servidor
                USUARIODOMINIO=$(echo "$(whoami)@$(hostname)")
                ssh -t "$USERNAME@$HOST" "sudo sed -i '/$USUARIODOMINIO/d' ~/.ssh/authorized_keys"
                #ssh -t "$USERNAME@$HOST" "sed -i '/$USUARIODOMINIO/d' ~/.ssh/authorized_keys"
            else
                # Eliminar clave del archivo authorized_keys en el servidor
                USUARIODOMINIO=$(echo "$(whoami)@$(hostname)")
                #ssh -t "$USERNAME@$HOST" "sudo sed -i '/$USUARIODOMINIO/d' ~/.ssh/authorized_keys"
                ssh -t "$USERNAME@$HOST" "sed -i '/$USUARIODOMINIO/d' ~/.ssh/authorized_keys"
            fi

            # Elimina la línea completa que contiene el usuario y host
            sed -i "/$USERNAME,$HOST/d" "$SSH_DIR/clientes.txt"

            # Borra el directorio de claves locales
            rm -rf "$SSH_DIR/$CLIENT_DIR_UNIQUE"

            # Elimina la huella del host
            ssh-keygen -R "$HOST"

            echo -e "${verde}Acceso de $USERNAME revocado y archivos locales eliminados.${borra_colores}"; sleep 2
        else
            echo -e "${rojo}No se pudo conectar al servidor${borra_colores} $DISPLAY_NAME${rojo} con usuario${borra_colores} $USERNAME@$HOST${rojo}.${borra_colores}"
            read -p "¿ quieres eliminar los arvhivos locales ? (s/n): " sn
            if [ "$sn" = "s" ] || [ "$sn" = "S" ]; then
                # Elimina igualmente los datos locales para limpiar el registro
                sed -i "/$USERNAME,$HOST/d" "$SSH_DIR/clientes.txt"
                rm -rf "$SSH_DIR/$CLIENT_DIR_UNIQUE"
                ssh-keygen -R "$HOST"
            else
                echo ""
                echo -e "${amarillo}No se borra nada${borra_colores}"
            fi
        fi
    else
        echo -e "${verde}Regresando al menu principal.${borra_colores}"
    fi
    sleep 2
}

#compruba la actualizacion y el ssoftware necesario
clear

# --- NUEVO: Atajo por línea de comandos ---
if [ "$1" == "-c" ] || [ "$1" == "connect" ]; then
    if [ "$TERMINAL" == "none" ]; then
        echo -e "${rojo}No se encontró un emulador de terminal compatible.${borra_colores}"
        exit 1
    else
        connect_client
        exit 0
    fi
fi
# ------------------------------------------

conexion

if [ $var_conexion = "si" ]
then
    var_conexion="si"
    software_necesario
    actualizar_script
else
    var_conexion="no"
    software_necesario
    var_software="si"
    var_actualizado="Imposible comprobar sin conexion a internet"
fi

# Bucle principal del menú con fzf y preview
while true; do
    clear
    echo ""
    if [ -s "$SSH_DIR/clientes.txt" ]; then
        OPTIONS_LIST="1) Agregar nuevo servidor SSH\n2) Conectarse a un servidor existente\n3) Revocar acceso a un servidor\n5) Salir"
    else
        OPTIONS_LIST="1) Agregar nuevo servidor SSH\n5) Salir"
    fi

    OPTION=$(printf "$OPTIONS_LIST" | fzf \
        --layout=reverse \
        --border \
        --border-label="Diseñado por SUKIGSX (Mail=scripts@mbbsistemas.es) (Web=https://repositorio.mbbsistemas.es)" \
        --prompt="Menú de Gestión de Servidores SSH: " \
        --preview-window=right:50% \
        --preview="case {} in
            *'Agregar nuevo servidor SSH'*)
                echo -e ' - Genera un par de claves.\n\n - Configura el acceso SSH para un nuevo servidor.' | fmt -w $(tput cols)
                ;;
            *'Conectarse a un servidor existente'*)
                echo -e ' - Conecta a uno o varios servidores. \n\n - Te los abre en terminales separadas. \n\n - Con ssh-manager.sh -c Abre directamente tus conexiones \n   puedes ponerlo en un alias. \n  ej. alias sshc=/ruta/completa/a/tu/ssh-manager.sh -c' | fmt -w $(tput cols)
                ;;
            *'Revocar acceso a un servidor'*)
                echo -e ' - Elimina la clave pública del servidor.\n\n - Elimina archivos locales del cliente.\n\n - Revoca el acceso.' | fmt -w $(tput cols)
                ;;
            *'Salir'*)
                echo -e ' - Termina el script.\n\n - Regresa a la terminal.' | fmt -w $(tput cols)
                ;;
        esac")

    case "$OPTION" in
        "1) Agregar nuevo servidor SSH")
            add_client
            ;;
        "2) Conectarse a un servidor existente")
            if [ "$TERMINAL" == "none" ]; then
                echo ""
                echo -e "${rojo}No se encontró un emulador de terminal compatible para abrir las conexiones.${borra_colores}"
                echo ""
                echo -e "${azul}Se recomienda instalar uno de estos emuladores de terminal:${borra_colores}"
                echo " - gnome-terminal"
                echo " - konsole"
                echo " - xfce4-terminal"
                echo " - xterm"
                echo " - terminator"
                echo ""
                read -p "Pulsa una tecla para continuar" pause
            else
                connect_client
            fi
            ;;
        "3) Revocar acceso a un servidor")
            revoke_access
            ;;
        "4) Revocar todos los accesos")
            revoke_all_clients
            ;;
        "5) Salir")
            ctrl_c
            ;;
        *)
            ;;
    esac
done

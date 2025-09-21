#!/bin/bash


# nc ssh-copy-id  ssh-keygen awk sed fzf

#colores
#ejemplo: echo -e "${verde} La opcion (-e) es para que pille el color.${borra_colores}"

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
echo -e " ${verde}- Gracias por utilizar mi script -${borra_colores}"
echo ""
exit
}

conexion(){
if ping -c1 google.com &>/dev/null
then
    #echo ""
    #echo -e " Conexion a internet [${verde}ok${borra_colores}]."
    var_conexion="si"
    #echo ""
else
    #echo ""
    #echo -e " Conexion a internet [${rojo}ko${borra_colores}]."
    var_conexion="no"
    echo ""
fi
}

software_necesario(){
var_software="no"
echo -e " Verificando software necesario:"
software="which git diff ping apt fzf curl jq nc ssh-copy-id  ssh-keygen awk sed" #ponemos el foftware a instalar separado por espacion dentro de las comillas ( soft1 soft2 soft3 etc )
for paquete in $software
do
which $paquete 2>/dev/null 1>/dev/null 0>/dev/null #comprueba si esta el programa llamado programa
sino=$? #recojemos el 0 o 1 del resultado de which
contador="1" #ponemos la variable contador a 1
    while [ $sino -gt 0 ] #entra en el bicle si variable programa es 0, no lo ha encontrado which
    do
        if [ $contador = "4" ] || [ $conexion = "no" ] 2>/dev/null 1>/dev/null 0>/dev/null #si el contador es 4 entre en then y sino en else
        then #si entra en then es porque el contador es igual a 4 y no ha podido instalar o no hay conexion a internet
            clear
            echo ""
            echo -e " ${amarillo}NO se ha podido instalar ${rojo}$paquete${amarillo}.${borra_colores}"
            echo -e " ${amarillo}Intentelo usted con la orden: (${borra_colores}sudo apt install $paquete ${amarillo})${borra_colores}"
            echo -e ""
            echo -e " ${rojo}No se puede ejecutar el script sin el software necesario.${borra_colores}"
            read pause
            exit
        else #intenta instalar
            echo " Instalando $paquete. Intento $contador/3."
            sudo apt install $paquete -y 2>/dev/null 1>/dev/null 0>/dev/null
            let "contador=contador+1" #incrementa la variable contador en 1
            which $paquete 2>/dev/null 1>/dev/null 0>/dev/null #comprueba si esta el programa en tu sistema
            sino=$? ##recojemos el 0 o 1 del resultado de which
        fi
    done
echo -e " [${verde}ok${borra_colores}] $paquete."
var_software="si"
done
}

actualizar_script(){
archivo_local="porsiaca.sh" # Nombre del archivo local
ruta_repositorio="https://github.com/sukigsx/pruebas.git" #ruta del repositorio para actualizar y clonar con git clone

# Obtener la ruta del script
descarga=$(dirname "$(readlink -f "$0")")
#descarga="/home/$(whoami)/scripts"
git clone $ruta_repositorio /tmp/comprobar >/dev/null 2>&1

diff $descarga/$archivo_local /tmp/comprobar/$archivo_local >/dev/null 2>&1


if [ $? = 0 ]
then
    #esta actualizado, solo lo comprueba
    echo ""
    #echo -e "${verde} El script${borra_colores} $0 ${verde}esta actualizado.${borra_colores}"
    #echo ""
    var_actualizado="si"
    chmod -R +w /tmp/comprobar
    rm -R /tmp/comprobar
else
    #hay que actualizar, comprueba y actualiza
    echo ""
    echo -e "${amarillo} EL script${borra_colores} $0 ${amarillo}NO esta actualizado.${borra_colores}"
    echo -e "${verde} Se procede a su actualizacion automatica.${borra_colores}"
    sleep 3
    mv /tmp/comprobar/$archivo_local $descarga
    chmod -R +w /tmp/comprobar
    rm -R /tmp/comprobar
    echo ""
    echo -e "${verde} El script se ha actualizado.${borra_colores}"
    sleep 2
    exit
    #kill -9 $(ps -o ppid= -p $$)
    #xdotool windowkill `xdotool getactivewindow`
fi
}
# Asegúrate de tener fzf y un emulador de terminal instalados.
# Puedes instalarlos con el gestor de paquetes de tu sistema.

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

                run_in_terminal "$DISPLAY_NAME ($USERNAME@$HOST)" "ssh -i \"$SSH_DIR/$CLIENT_DIR_UNIQUE/id_rsa\" \"$USERNAME@$HOST\"" > /dev/null 2>&1
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
                echo -e ' - Conecta a uno o varios servidores. \n\n - Te los abre en terminales separadas.' | fmt -w $(tput cols)
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

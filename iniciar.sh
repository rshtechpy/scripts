#!/bin/bash

VERDE="\033[0;32m"
RESET="\033[0m"

# Tomar el hostname del primer argumento
nuevo_hostname="$1"

if [ -z "$nuevo_hostname" ]; then
    echo -e "${VERDE}❌ Debes pasar el nuevo hostname como argumento:${RESET}"
    echo -e "${VERDE}   Ejemplo: curl -sSL bit.ly/update_vm | bash -s nuevo-host${RESET}"
    exit 1
fi

echo -e "${VERDE}🔄 Actualizando el sistema...${RESET}"
sudo apt update && sudo apt upgrade -y

echo -e "${VERDE}✅ Cambiando hostname a: $nuevo_hostname${RESET}"
echo "$nuevo_hostname" | sudo tee /etc/hostname
sudo hostnamectl set-hostname "$nuevo_hostname"
sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$nuevo_hostname/" /etc/hosts

echo -e "${VERDE}🔄 Instalando Docker...${RESET}"
# Instalar dependencias necesarias
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Agregar la clave GPG oficial de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Agregar el repositorio de Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Actualizar nuevamente e instalar Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Agregar el usuario actual al grupo docker para no necesitar sudo
sudo usermod -aG docker $USER

echo -e "${VERDE}✅ Docker instalado correctamente.${RESET}"
echo -e "${VERDE}ℹ️  Para que los cambios de grupo surtan efecto, necesitas cerrar sesión y volver a entrar o reiniciar el sistema.${RESET}"

echo -e "${VERDE}✅ Proceso completado. Puedes reiniciar para aplicar todos los cambios.${RESET}"

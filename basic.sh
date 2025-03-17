#!/bin/bash
#INSTALADOR CREADO POR RONALD SCHNEIDER DE RSHTECH PY 2025
# Actualizar y mejorar el sistema
echo "Actualizando el sistema..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

# Instalar dependencias necesarias
echo "Instalando dependencias..."
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Añadir la clave GPG oficial de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Añadir el repositorio de Docker a las fuentes de APT
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Actualizar nuevamente el índice de paquetes
sudo apt-get update -y

# Instalar Docker
echo "Instalando Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Iniciar y habilitar el servicio de Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verificar la instalación de Docker
docker --version

# Obtener la IP pública del VPS
PUBLIC_IP=$(curl -s ifconfig.me)

# Inicializar Docker Swarm con la IP pública
echo "Inicializando Docker Swarm con la IP pública: $PUBLIC_IP..."
sudo docker swarm init --advertise-addr $PUBLIC_IP

# Crear la red Docker en modo Swarm
echo "Creando la red Docker 'red_docker'..."
sudo docker network create --driver=overlay red_docker

# Crear los volúmenes necesarios para Traefik
echo "Creando volúmenes para Traefik..."
sudo docker volume create volume_swarm_shared
sudo docker volume create volume_swarm_certificates

# Preguntar al usuario por el correo electrónico para Let's Encrypt
read -p "Introduce tu correo electrónico para Let's Encrypt: " EMAIL

# Crear el archivo traefik.yml
echo "Creando el archivo traefik.yml..."
cat <<EOF > traefik.yml
version: "3.7"

services:

  traefik:
    image: traefik:v2.11.2
    command:
      - "--api.dashboard=true"
      - "--providers.docker.swarmMode=true"
      - "--providers.docker.endpoint=unix:///var/run/docker.sock"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=red_docker"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.web.http.redirections.entrypoint.permanent=true"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.letsencryptresolver.acme.email=$EMAIL"
      - "--certificatesresolvers.letsencryptresolver.acme.storage=/etc/traefik/letsencrypt/acme.json"
      - "--log.level=DEBUG"
      - "--log.format=common"
      - "--log.filePath=/var/log/traefik/traefik.log"
      - "--accesslog=true"
      - "--accesslog.filepath=/var/log/traefik/access-log"
    deploy:
      placement:
        constraints:
          - node.role == manager
      restart_policy:
        condition: on-failure
        delay: 5s
      labels:
        - "traefik.enable=true"
        - "traefik.http.middlewares.redirect-https.redirectscheme.scheme=https"
        - "traefik.http.middlewares.redirect-https.redirectscheme.permanent=true"
        - "traefik.http.routers.http-catchall.rule=hostregexp(\`{host:.+}\`)"
        - "traefik.http.routers.http-catchall.entrypoints=web"
        - "traefik.http.routers.http-catchall.middlewares=redirect-https@docker"
        - "traefik.http.routers.http-catchall.priority=1"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "vol_certificates:/etc/traefik/letsencrypt"
    ports:
      - target: 80
        published: 80
        mode: host
      - target: 443
        published: 443
        mode: host
    networks:
      - red_docker

volumes:

  vol_shared:
    external: true
    name: volume_swarm_shared
  vol_certificates:
    external: true
    name: volume_swarm_certificates

networks:

  red_docker:
    external: true
    name: red_docker
EOF

# Desplegar la stack de Traefik
echo "Desplegando la stack de Traefik..."
sudo docker stack deploy -c traefik.yml traefik

# Esperar unos segundos para que Traefik se inicie correctamente
echo "Esperando 10 segundos para que Traefik se inicie..."
sleep 10

# Preguntar al usuario por el subdominio para Portainer
read -p "Introduce el subdominio para Portainer (por ejemplo, portainer.dominio.com): " SUBDOMINIO

# Crear el archivo portainer.yml
echo "Creando el archivo portainer.yml..."
cat <<EOF > portainer.yml
version: "3.7"

services:

  agent:
    image: portainer/agent:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    networks:
      - red_docker
    deploy:
      mode: global
      placement:
        constraints: [node.platform.os == linux]

  portainer:
    image: portainer/portainer-ce:latest
    command: -H tcp://tasks.agent:9001 --tlsskipverify
    volumes:
      - portainer_data:/data
    networks:
      - red_docker
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
      labels:
        - "traefik.enable=true"
        - "traefik.docker.network=red_docker"
        - "traefik.http.routers.portainer.rule=Host(\`$SUBDOMINIO\`)"
        - "traefik.http.routers.portainer.entrypoints=websecure"
        - "traefik.http.routers.portainer.priority=1"
        - "traefik.http.routers.portainer.tls.certresolver=letsencryptresolver"
        - "traefik.http.routers.portainer.service=portainer"
        - "traefik.http.services.portainer.loadbalancer.server.port=9000"

networks:
  red_docker:
    external: true
    attachable: true
    name: red_docker

volumes:
  portainer_data:
    external: true
    name: portainer_data
EOF

# Crear el volumen para Portainer
echo "Creando volumen para Portainer..."
sudo docker volume create portainer_data

# Desplegar la stack de Portainer
echo "Desplegando la stack de Portainer..."
sudo docker stack deploy -c portainer.yml portainer

# Obtener el comando para unir workers al Swarm
JOIN_COMMAND=$(sudo docker swarm join-token worker | grep "docker swarm join")

# Mostrar el comando para unir workers al Swarm
echo ""
echo "Para unir workers al Swarm, ejecuta el siguiente comando en los nodos workers:"
echo ""
echo "    $JOIN_COMMAND"
echo ""

# Mostrar los datos para acceder a Portainer
echo ""
echo "Para acceder a Portainer, visita:"
echo ""
echo "    https://$SUBDOMINIO"
echo ""
echo "Asegúrate de que el subdominio esté configurado en tu DNS para apuntar a la IP pública del VPS."
echo ""

echo "Proceso completado."

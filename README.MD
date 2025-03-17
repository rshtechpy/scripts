markdown
Copy
# 🐳 Docker Swarm + Traefik + Portainer Setup 🚀

Este repositorio contiene un script automatizado para configurar un clúster de Docker Swarm con Traefik como reverse proxy y Portainer para la gestión visual de contenedores. ¡Todo listo en minutos! ⏱️

---

## 📋 Requisitos

- **Ubuntu** (recomendado) 🐧
- **Acceso root o sudo** 🔑
- **Conexión a Internet** 🌐

---

## 🛠️ ¿Qué hace el script?

1. **Actualiza el sistema** 🔄
2. **Instala Docker** 🐳
3. **Configura Docker Swarm** 🐝
4. **Despliega Traefik** 🚦
5. **Despliega Portainer** 🖥️
6. **Configura Let's Encrypt para HTTPS** 🔒

---

## 🚀 Cómo usar el script

1. Clona este repositorio:
   ```bash
   git clone https://github.com/tu-usuario/tu-repositorio.git
   cd tu-repositorio
Haz que el script sea ejecutable:

bash
Copy
chmod +x deploy_traefik_portainer.sh
Ejecuta el script:

bash
Copy
./deploy_traefik_portainer.sh
Sigue las instrucciones en pantalla:

Introduce tu correo electrónico para Let's Encrypt 📧

Introduce el subdominio para Portainer (por ejemplo, portainer.dominio.com) 🌍

🖥️ Acceso a Portainer
Una vez finalizado el script, podrás acceder a Portainer en:

Copy
https://portainer.tu-dominio.com
🐝 Unir workers al Swarm
El script generará un comando para unir otros nodos al Swarm. Ejecuta ese comando en los nodos workers:

bash
Copy
docker swarm join --token SWMTKN-1-abcdefghijklmnopqrstuvwxyz-abcdefghijklmnop 192.168.1.100:2377
📂 Estructura del proyecto
deploy_traefik_portainer.sh: Script principal para configurar todo.

traefik.yml: Archivo de configuración de Traefik generado automáticamente.

portainer.yml: Archivo de configuración de Portainer generado automáticamente.

📜 Licencia
Este proyecto está bajo la licencia MIT. ¡Siéntete libre de usarlo y modificarlo! 🎉

🙌 Contribuciones
¡Las contribuciones son bienvenidas! Si encuentras algún problema o tienes una mejora, abre un issue o envía un pull request. 🤝

📧 Contacto
¿Preguntas? ¡Contáctame! 📬

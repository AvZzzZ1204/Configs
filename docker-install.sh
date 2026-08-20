#!/bin/bash
set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Instalación de Docker Engine y Docker Compose ===${NC}"

# Función para verificar e instalar dependencias faltantes
check_and_install() {
    local cmd=$1
    local pkg=$2
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${YELLOW}⚠️  Comando '$cmd' no encontrado. Intentando instalar '$pkg'...${NC}"
        sudo apt-get update -qq
        sudo apt-get install -y "$pkg"
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}❌ No se pudo instalar '$pkg'. Por favor, instálalo manualmente y vuelve a ejecutar el script.${NC}"
            exit 1
        else
            echo -e "${GREEN}✅ '$pkg' instalado correctamente.${NC}"
        fi
    else
        echo -e "${GREEN}✅ Comando '$cmd' encontrado.${NC}"
    fi
}

# 1. Verificar e instalar dependencias básicas
echo -e "${YELLOW}Verificando dependencias...${NC}"
check_and_install "curl" "curl"
check_and_install "gpg" "gnupg"
check_and_install "lsb_release" "lsb-release"
check_and_install "apt-get" "apt"  # Por si acaso (suele estar siempre)

# 2. Detectar distribución
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    VERSION=$VERSION_CODENAME
else
    echo -e "${RED}No se pudo detectar la distribución.${NC}"
    exit 1
fi

if [[ "$DISTRO" != "ubuntu" && "$DISTRO" != "debian" ]]; then
    echo -e "${RED}Este script solo soporta Ubuntu y Debian.${NC}"
    exit 1
fi

echo -e "${YELLOW}Distribución detectada: $DISTRO $VERSION${NC}"

# 3. Desinstalar paquetes antiguos
echo -e "${YELLOW}Eliminando paquetes antiguos de Docker...${NC}"
sudo apt-get remove -y docker.io docker-doc docker-compose podman-docker containerd runc 2>/dev/null || true

# 4. Agregar repositorio oficial de Docker
echo -e "${YELLOW}Agregando repositorio oficial de Docker...${NC}"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO $VERSION stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Instalar Docker Engine y el plugin de Compose
echo -e "${YELLOW}Instalando Docker Engine y Docker Compose...${NC}"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 6. Verificar instalación
echo -e "${YELLOW}Verificando instalación...${NC}"
docker --version
docker compose version

echo -e "${GREEN}✅ Docker y Docker Compose instalados correctamente.${NC}"
echo -e "${YELLOW}Para usar Docker sin sudo, ejecuta: sudo usermod -aG docker \$USER y reinicia sesión.${NC}"
# ============================================================
# Dockerfile - BVG PostgreSQL
# Imagen personalizada con los scripts precargados
#
# Uso:
#   docker build -t bvg-postgres .
#   docker run -d -p 5432:5432 --name bvg_db bvg-postgres
# ============================================================

FROM postgres:15

LABEL maintainer="BVG - Banco de Vivienda Guatemala"
LABEL description="PostgreSQL 15 con schema BVG precargado"

# Variables de entorno por defecto (sobreescribibles)
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=BVG_Pass2024!
ENV POSTGRES_DB=bvg

# Copiar scripts SQL al directorio de inicialización
# Docker los ejecuta automáticamente en orden alfabético
COPY sql/init/ /docker-entrypoint-initdb.d/

# Puerto estándar de PostgreSQL
EXPOSE 5432

# Volumen para persistencia de datos
VOLUME ["/var/lib/postgresql/data"]
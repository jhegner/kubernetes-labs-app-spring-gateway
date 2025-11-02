# =======================
# Stage 1 - Build
# =======================
FROM eclipse-temurin:21-jdk-alpine AS build

# Define variáveis de ambiente
ARG MAVEN_VERSION=3.9.9-r0

# Instala Maven no build stage
RUN apk update && apk upgrade && \
    apk add --no-cache maven=$MAVEN_VERSION

WORKDIR /app

# Copia o pom.xml primeiro (para cache de dependências)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copia o código fonte e compila
COPY src ./src
RUN mvn clean package -DskipTests


# =======================
# Stage 2 - Runtime (Temurin JRE)
# =======================
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Copia o JAR gerado no build
COPY --from=build /app/target/kubernetes-labs-*.jar application.jar

# Define variáveis de ambiente
ARG TZDATA_VERSION=2025b-r0
ARG CURL_VERSION=8.14.1-r2
ARG BASH_VERSION=5.2.37-r0

# Instala o timezone America/Sao_Paulo e utilitários úteis para debug
RUN apk update && apk upgrade && \
    apk add --no-cache bash="$BASH_VERSION" curl="$CURL_VERSION" tzdata="$TZDATA_VERSION"  && \
    cp /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    echo "America/Sao_Paulo" > /etc/timezone && \
    apk del tzdata && \
    rm -rf /var/cache/apk/*

# Expõe a porta 8080 da aplicação
EXPOSE 8080

# Comando para rodar a aplicação
ENTRYPOINT ["java", "-jar", "application.jar"]
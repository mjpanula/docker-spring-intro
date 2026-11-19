# --- Vaihe 1: käännös (Maven + JDK 11) -------------------------------------
FROM docker.io/library/maven:3.9-eclipse-temurin-11 AS build
WORKDIR /src
# Ensin pelkkä pom.xml: riippuvuudet ladataan omaan kerrokseen, joka säilyy
# välimuistissa niin kauan kuin pom.xml ei muutu.
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
# Sitten lähdekoodi ja paketointi (testit ohitetaan konttikäännöksessä)
COPY src ./src
RUN mvn -B -q -DskipTests package && cp target/*.jar /src/app.jar

# --- Vaihe 2: ajo (pelkkä JRE 11) ------------------------------------------
FROM docker.io/library/eclipse-temurin:11-jre
WORKDIR /app
COPY --from=build /src/app.jar /app/app.jar

# Rahti (OpenShift) ajaa kontin satunnaisella UID:llä, joka kuuluu ryhmään 0.
# Siksi kirjoitettavat hakemistot annetaan ryhmälle 0 samoin oikeuksin kuin omistajalle.
RUN mkdir -p /data && chgrp -R 0 /app /data && chmod -R g=u /app /data

# H2-tietokanta tiedostoon /data (application.properties käyttää ./database).
# Spring lukee ympäristömuuttujan SPRING_DATASOURCE_URL ominaisuutena spring.datasource.url.
ENV SPRING_DATASOURCE_URL=jdbc:h2:file:/data/database \
    JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -Djava.io.tmpdir=/tmp"

USER 1001
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]

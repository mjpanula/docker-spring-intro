# docker-spring-intro

Esimerkki ja ohjeet Spring Boot -sovelluksen paketoimisesta **Docker-konttiin** ja ajamisesta
CSC:n **Rahti**-palvelussa (OpenShift).

| Tiedosto | Sisältö |
|---|---|
| [DOCKER-PERUSTEET.md](DOCKER-PERUSTEET.md) | Konttien perusteet: Docker Desktop ja Podman, peruskomennot, konttirekisterit, CI/CD-työnkulku ja ilmaiset ajopaikat (esim. Render) |
| [RAHTI-OHJE.md](RAHTI-OHJE.md) | `oc`-komennon asennus ja käyttö, JDK 11 -kontin buildaus ja julkaisu Rahtiin vaihe vaiheelta |
| [Dockerfile](Dockerfile) | Monivaiheinen buildi: Maven + JDK 11 → JRE 11 |
| `src/`, `pom.xml` | Esimerkkisovellus: Spring Boot 2.1, Spring Security, JPA + H2 |

## Pikakokeilu

```bash
docker build -t hellodb .          # tai: podman build -t hellodb .
docker run --rm -p 18080:8080 hellodb
```

Avaa <http://localhost:18080/accounts>, luo tunnus ja kirjaudu.

Ilman Dockeria (vaatii JDK:n ja Mavenin): `mvn spring-boot:run` → <http://localhost:8080/accounts>.

## Alkuperä

Esimerkkisovellus perustuu Helsingin yliopiston
[Web-palvelinohjelmointi](https://mooc.fi/)-kurssin tehtävään *Osa05_05.HelloDbAuthentication*.
Tähän repoon on lisätty Dockerfile ja ohjeet.

Spring Boot 2.1 ja Java 11 ovat vanhoja, eikä niihin enää tule tietoturvapäivityksiä, joten
sovellus on tarkoitettu vain opetuskäyttöön.

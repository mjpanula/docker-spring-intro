# Docker-konttien perusteet

Lyhyt johdanto kontteihin: mitä ne ovat, millä niitä ajetaan, miten image tehdään ja jaetaan
ja minne sen voi viedä ajoon. Rahti-kohtaiset ohjeet ovat tiedostossa
[RAHTI-OHJE.md](RAHTI-OHJE.md).

Linkit ovat lisämateriaalia. Hyviä kokonaisuuksia:

- [DevOps with Docker](https://devopswithdocker.com/) – Helsingin yliopiston ilmainen
  verkkokurssi (englanniksi), käy perusteista Compose-tiedostoihin ja tietoturvaan asti.
- [Docker: Get started](https://docs.docker.com/get-started/) – Dockerin oma aloitusopas.
- [IONOS: Docker-opas aloittelijoille](https://www.ionos.com/fi-fi/digitalguide/palvelin/asetukset/docker-opas-asennus-ja-ensimmaeiset-askeleet/)
  – suomenkielinen johdanto asennukseen ja ensimmäisiin komentoihin.

## 1. Mikä kontti on?

| Termi | Selitys |
|---|---|
| **Image** (konttikuva) | Paketti, jossa on sovellus **ja kaikki sen tarvitsemat asiat**: käyttöjärjestelmän peruskirjastot, ajoympäristö (esim. Java 11 JRE) ja sovelluksen tiedostot. Image on muuttumaton. |
| **Kontti** (container) | Imagesta käynnistetty, eristetty prosessi. Samasta imagesta voi ajaa monta konttia. |
| **Dockerfile** | Resepti, jonka mukaan image rakennetaan (`docker build`). |
| **Registry** (konttirekisteri) | Palvelin, jossa imageja säilytetään ja josta niitä ladataan, esim. Docker Hub, GitHub Container Registry tai Rahdin sisäinen rekisteri. |
| **Tag** | Imagen versio: `eclipse-temurin:11-jre`, `oma-sovellus:1.2.0`, `:latest`. |

Kontti ei ole virtuaalikone. Se jakaa isäntäkoneen Linux-ytimen, joten se käynnistyy
sekunneissa ja vie vähän muistia. Windowsissa ja macOS:ssä Linux-kontit ajetaan kevyen
Linux-virtuaalikoneen sisällä (Windowsissa WSL2), jonka Docker Desktop tai Podman Desktop
hoitaa automaattisesti.
Lisää: [IONOS: Docker vs. virtuaalikoneet](https://www.ionos.com/fi-fi/digitalguide/palvelin/osaaminen/docker-vs-virtuaalikoneet/).

## 2. Työkalut: Docker Desktop ja Podman

### Docker Desktop

[Docker Desktop](https://docs.docker.com/desktop/) sisältää Docker-moottorin,
komentorivityökalut ja **graafisen käyttöliittymän**. Käyttöliittymästä näkee imaget,
käynnissä olevat kontit ja niiden lokit, ja kontteja voi käynnistää ja pysäyttää klikkaamalla.

- **Windowsissa** Docker Desktop käyttää oletuksena **WSL2:ta**. Kontit pyörivät WSL2:n
  Linux-ympäristössä, ja `docker`-komento toimii sekä PowerShellissä että WSL2:n Ubuntussa.
  Ohjeet: [Docker Desktop WSL 2 backend](https://docs.docker.com/desktop/features/wsl/) ja
  Microsoftin [Docker-säilöjen käytön aloittaminen WSL:ssä](https://learn.microsoft.com/fi-fi/windows/wsl/tutorials/wsl-containers)
  (suomeksi).
- **Lisenssi:** Docker Desktop on **ilmainen henkilökohtaiseen käyttöön, opiskeluun ja
  opetukseen**, ei-kaupallisiin avoimen lähdekoodin projekteihin sekä pienyrityksille (alle
  250 työntekijää **ja** alle 10 M$ liikevaihto). Suurempien yritysten työkäytössä se vaatii
  maksullisen tilauksen. Ks. [Docker Desktop license agreement](https://docs.docker.com/subscription/desktop-license/).
  Tällä kurssilla voit siis käyttää sitä ilmaiseksi.

### Podman

[Podman](https://podman.io/) on Red Hatin kehittämä, **aidosti avoin ja ilmainen**
(Apache 2.0 -lisenssi) vaihtoehto. Sen lisenssiehdot eivät riipu käyttäjästä tai yrityksen
koosta.

- Komennot ovat **pitkälti samat kuin Dockerissa** (`podman build`, `podman run`,
  `podman push`…). Monet käyttävät aliasta `alias docker=podman`.
- Se käyttää samoja imageja ja Dockerfileja (OCI-standardi). Docker Hubin imaget toimivat sellaisenaan.
- Siinä ei ole taustalla pyörivää root-palvelua (daemonless), ja kontit ajetaan oletuksena
  ilman root-oikeuksia (rootless), mikä on tietoturvan kannalta parempi.
- [Podman Desktop](https://podman-desktop.io/) tarjoaa Docker Desktopin kaltaisen
  graafisen käyttöliittymän Windowsiin (WSL2), macOS:ään ja Linuxiin.
- Pieniä eroja on. Esimerkiksi Compose-tiedostot vaativat `podman compose` -komennon taustalle
  erillisen työkalun (`podman-compose` tai `docker-compose`), ja Docker-moottorin sisäisiin
  asetuksiin nojaavat työkalut voivat vaatia säätöä.
  Ks. [Podman-dokumentaatio](https://docs.podman.io/en/latest/).

Tämän kurssin esimerkit on testattu Podmanilla (Fedora Linux), mutta komennot toimivat sellaisinaan
myös Dockerilla: vaihda `podman` → `docker`.

## 3. Peruskomennot

```bash
docker run --rm -p 8080:8080 docker.io/library/nginx   # lataa image ja käynnistä kontti
docker ps                       # käynnissä olevat kontit (-a: myös pysähtyneet)
docker logs -f <kontti>         # kontin loki
docker exec -it <kontti> sh     # shell kontin sisään
docker stop <kontti>            # pysäytä
docker images                   # paikalliset imaget
docker build -t oma-sovellus:1.0 .     # rakenna image nykyisen kansion Dockerfilestä
docker tag oma-sovellus:1.0 käyttäjä/oma-sovellus:1.0
docker push käyttäjä/oma-sovellus:1.0  # vie image rekisteriin
docker pull käyttäjä/oma-sovellus:1.0  # lataa image rekisteristä
docker system prune             # siivoa käyttämättömät imaget ja kontit
```

Tärkeimmät `docker run` -valitsimet:

| Valitsin | Merkitys |
|---|---|
| `-p 18080:8080` | Isäntäkoneen portti 18080 → kontin portti 8080 |
| `-e SPRING_PROFILES_ACTIVE=prod` | Ympäristömuuttuja (Spring lukee asetukset myös näistä) |
| `-v data:/data` | Nimetty volyymi kontin hakemistoon `/data`, jolloin data säilyy kontin poiston jälkeen |
| `--rm` | Poista kontti, kun se pysähtyy |
| `-d` | Aja taustalla |

## 4. Dockerfile Spring Boot -sovellukselle

Tämän repon [Dockerfile](Dockerfile) on monivaiheinen (multi-stage):

1. Ensimmäinen vaihe kääntää sovelluksen Maven + JDK 11 -imagessa.
2. Toinen vaihe kopioi valmiin jarin pelkkään JRE-imageen.

Näin lopullisessa imagessa ei ole Mavenia eikä lähdekoodia. Kääntäminen ei myöskään vaadi
omalle koneelle JDK:ta eikä Mavenia.

```bash
docker build -t hellodb .
docker run --rm -p 18080:8080 hellodb
# selaimella http://localhost:18080/accounts
```

Yksityiskohtainen selitys on tiedostossa [RAHTI-OHJE.md, kohta 5](RAHTI-OHJE.md#5-esimerkki-jdk-11--kontti-olemassa-olevasta-spring-sovelluksesta).
Lisää: [Spring Boot Docker -opas](https://spring.io/guides/topicals/spring-boot-docker) ja
[Spring Boot: Dockerfiles](https://docs.spring.io/spring-boot/reference/packaging/container-images/dockerfiles.html).
Valmiit Java-pohjaimaget: [eclipse-temurin Docker Hubissa](https://hub.docker.com/_/eclipse-temurin).

## 5. Imagen jakaminen: konttirekisterit

Image viedään rekisteriin `push`-komennolla, ja mikä tahansa kone tai pilvipalvelu voi hakea
sen `pull`-komennolla. Imagen nimi kertoo, missä rekisterissä se on:

| Rekisteri | Imagen nimen muoto | Huomioita |
|---|---|---|
| **Docker Hub** | `docker.io/käyttäjä/sovellus:tag` | Ilmaisella [Docker-tilillä](https://hub.docker.com/signup) voi pushata rajattomasti julkisia imageja. Yksityisiä repoja on ilmaistilillä 1. Latausmääriä rajoitetaan etenkin ilman kirjautumista ([Docker Hub usage and limits](https://docs.docker.com/docker-hub/usage/)). |
| **GitHub Container Registry** | `ghcr.io/käyttäjä/sovellus:tag` | Kuuluu GitHubiin, ja julkiset imaget ovat ilmaisia. GitHub Actions voi pushata sinne repon omalla `GITHUB_TOKEN`illa. [Ohje](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry) |
| **GitLab Container Registry** | `registry.gitlab.com/ryhmä/projekti:tag` | Jokaisella GitLab-projektilla on oma rekisteri. [Ohje](https://docs.gitlab.com/user/packages/container_registry/) |
| **Yrityksen oma rekisteri** | esim. `registry.firma.fi/tiimi/sovellus:tag` | GitLabin, Harborin, Nexuksen, Artifactoryn tai pilvipalvelun (AWS ECR, Azure ACR, Google Artifact Registry) rekisteri. |
| **Rahdin sisäinen rekisteri** | `image-registry.apps.2.rahti.csc.fi/projekti/sovellus:tag` | Ks. [CSC: Using Rahti integrated registry](https://docs.csc.fi/cloud/rahti/usage/images/integrated-registry/). |

Esimerkki, Docker Hub:

```bash
docker login                                  # Docker Hub -tunnuksilla
docker build -t käyttäjä/hellodb:1.0 .
docker push käyttäjä/hellodb:1.0
```

## 6. Tyypillinen työnkulku yrityksessä (CI/CD)

```text
 kehittäjä            CI-palvelu (GitLab CI, GitHub Actions, Jenkins…)        ajoympäristö
 ─────────            ─────────────────────────────────────────────           ────────────
 git push   ──►  1. testit (mvn test)                                        Kubernetes /
                 2. docker build -t registry.firma.fi/app:<commit> .          OpenShift /
                 3. docker push registry.firma.fi/app:<commit>   ──►  rekisteri  ──► pilvipalvelu
                 4. päivitä ajoympäristö käyttämään uutta imagea               hakee imagen
```

1. Kehittäjä pushaa koodin Git-repoon.
2. **CI-putki** (esim. GitLab CI) ajaa testit ja rakentaa imagen repon Dockerfilestä.
3. Image tagataan versiolla tai commit-tunnisteella ja viedään **yrityksen sisäiseen
   konttirekisteriin**.
4. Testi- ja tuotantoympäristöt (Kubernetes, OpenShift, pilvipalvelu) hakevat imagen
   rekisteristä ja käynnistävät sen. Kaikissa ympäristöissä ajetaan siis täsmälleen sama,
   kerran rakennettu ja testattu image.

Lisää:
- [GitLab: Use Docker to build Docker images](https://docs.gitlab.com/ci/docker/using_docker_build/)
- [Docker: GitHub Actions](https://docs.docker.com/build/ci/github-actions/)

## 7. Minne kontin voi viedä ajoon?

**Image sisältää kaiken tarvittavan**, joten julkisesta rekisteristä ladattavissa olevan imagen
saa ajoon lähes mihin tahansa konttipalveluun ilman sen kummempaa säätöä. Palvelulle kerrotaan
imagen nimi ja portti, ja se hoitaa loput:

| Palvelu | Huomioita |
|---|---|
| **[Render](https://render.com/)** | Ilmainen *Free*-instanssi web-palveluille. Sovelluksen voi rakentaa Git-repon Dockerfilestä tai [ajaa valmiin imagen](https://render.com/docs/deploying-an-image) Docker Hubista, GHCR:stä, GitLabista ym. [Free-tason rajoitukset](https://render.com/docs/free): 750 tuntia/kk, sammuu 15 minuutin käyttämättömyyden jälkeen (seuraava pyyntö herättää sen noin minuutissa), ja tiedostojärjestelmä tyhjenee uudelleenkäynnistyksessä. |
| **[CSC Rahti](https://docs.csc.fi/cloud/rahti/)** | Suomalainen OpenShift-palvelu korkeakouluille. Ks. [RAHTI-OHJE.md](RAHTI-OHJE.md). |
| Muut | Esim. Google Cloud Run, Azure Container Apps, AWS App Runner / ECS, Fly.io sekä mikä tahansa Kubernetes. Palveluilla on usein ilmaiskiintiö tai opiskelijakrediittejä, mutta ne vaativat tyypillisesti maksukortin. |

Esimerkki: kun image on Docker Hubissa nimellä `käyttäjä/hellodb:1.0`, Renderissä valitaan
*New → Web Service → Existing image*, kirjoitetaan imagen nimi ja valitaan Free-instanssi.

"Lähes mihin tahansa" sisältää muutaman ehdon:

- **Prosessoriarkkitehtuuri:** Apple Silicon -Macilla (ARM) rakennettu image ei oletuksena toimi
  x86-palvelimella. Rakenna oikealle alustalle:
  `docker buildx build --platform linux/amd64 -t … .`
- **Asetukset ja salaisuudet** (tietokannan osoite, API-avaimet) annetaan
  ympäristömuuttujina ajoympäristössä. Niitä ei kirjoiteta imageen, koska julkisen imagen
  sisällön voi lukea kuka tahansa.
- **Pysyvä data:** kontin tiedostojärjestelmä on väliaikainen. Tämän repon sovelluksen H2-tiedostokanta
  katoaisi Renderin Free-tasolla jokaisessa uudelleenkäynnistyksessä. Käytä pysyvää levyä
  (Rahdin PVC) tai erillistä tietokantapalvelua (esim. PostgreSQL).
- **Portti:** kerro palvelulle, mitä porttia sovellus kuuntelee (Spring Boot: 8080), tai
  vaihda portti ympäristömuuttujalla `SERVER_PORT`.
- **Käyttäjä:** jotkin alustat (kuten Rahti/OpenShift) ajavat kontin satunnaisella
  käyttäjätunnuksella, ks. [RAHTI-OHJE.md, kohta 7](RAHTI-OHJE.md#7-sudenkuopat).

## 8. Lisämateriaalia

Suomeksi:
- [IONOS: Docker-opas aloittelijoille](https://www.ionos.com/fi-fi/digitalguide/palvelin/asetukset/docker-opas-asennus-ja-ensimmaeiset-askeleet/)
- [IONOS: Docker Compose -opas](https://www.ionos.com/fi-fi/digitalguide/palvelin/asetukset/docker-compose-opas/) –
  usean kontin sovellukset (esim. Spring + PostgreSQL)
- [Microsoft: Docker-säilöjen käytön aloittaminen WSL:ssä](https://learn.microsoft.com/fi-fi/windows/wsl/tutorials/wsl-containers)

Englanniksi:
- [DevOps with Docker](https://devopswithdocker.com/) (Helsingin yliopisto)
- [Docker: Get started](https://docs.docker.com/get-started/)
- [Podman: Getting started](https://podman.io/get-started)
- [Spring Boot Docker -opas](https://spring.io/guides/topicals/spring-boot-docker)
- [CSC Rahti -dokumentaatio](https://docs.csc.fi/cloud/rahti/) ja
  [Rahti: kontti-imagejen tekeminen](https://docs.csc.fi/cloud/rahti/usage/images/creating/)

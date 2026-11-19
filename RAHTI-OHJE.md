# Spring Boot -sovellus konttina CSC:n Rahtiin – `oc`-komennon käyttöohje

Tämä ohje näyttää, miten Spring Boot -sovellus paketoidaan konttiin ja ajetaan CSC:n
**Rahti**-palvelussa (OpenShift / Kubernetes) komentorivityökalulla `oc`.

Ohjeen esimerkkinä on tämän repon sovellus (Web-palvelinohjelmoinnin tehtävä *HelloDbAuthentication*)
(Spring Boot 2.1, Spring Security, JPA + H2-tietokanta). Siitä tehdään **JDK 11** -kontti.
Kaikki ohjeen komennot on ajettu oikeasti 19.11.2026, ja tulosteet ovat niistä ajoista
(lyhennettyinä). Esimerkkisovellus pyöri osoitteessa `https://hellodb-ltitest.2.rahtiapp.fi`.

Jos kontit ovat uusi asia, lue ensin [DOCKER-PERUSTEET.md](DOCKER-PERUSTEET.md).

Sisältö:

1. [Käsitteet](#1-käsitteet)
2. [oc:n asennus ja kirjautuminen](#2-ocn-asennus-ja-kirjautuminen)
3. [oc:n peruskomennot](#3-ocn-peruskomennot)
4. [Miten konttien buildaus tehdään (ja miten se tehtiin testiprojektissa)](#4-miten-konttien-buildaus-tehdään)
5. [Esimerkki: JDK 11 -kontti olemassa olevasta Spring-sovelluksesta](#5-esimerkki-jdk-11--kontti-olemassa-olevasta-spring-sovelluksesta)
6. [Sovelluksen päivitys](#6-sovelluksen-päivitys)
7. [Sudenkuopat](#7-sudenkuopat)
8. [Siivous](#8-siivous)
9. [Komentojen pikaopas](#9-komentojen-pikaopas)

---

## 1. Käsitteet

| Käsite | Mitä se on |
|---|---|
| **Project** (namespace) | Oma "tila" Rahdissa. Projekti luodaan web-konsolissa, ja sille annetaan CSC-projektin numero (laskutus). Esimerkeissä projekti on `ltitest`. |
| **BuildConfig** | Ohje kontin rakentamiseen Rahdissa: mistä lähdekoodi tulee ja millä strategialla (Docker, S2I) image rakennetaan. |
| **Build** | Yksi BuildConfigin ajokerta (`hellodb-1`, `hellodb-2`, …). |
| **ImageStream** | Rahdin sisäinen viittaus konttikuvaan (`hellodb:latest`). Kun buildi tuottaa uuden imagen, siihen kytketty Deployment päivittyy automaattisesti. |
| **Deployment** | Kertoo, montako kopiota (podia) imagesta ajetaan, millä ympäristömuuttujilla, levyillä, resursseilla ja terveystarkistuksilla. |
| **Pod** | Ajossa oleva kontti. Podit ovat kertakäyttöisiä: uudelleenkäynnistyksessä tilalle tulee uusi pod, ja sen paikallinen levy on tyhjä. |
| **Service** | Klusterin sisäinen, pysyvä osoite podeille (`hellodb:8080`). |
| **Route** | Julkinen osoite internetiin (`https://hellodb-ltitest.2.rahtiapp.fi`). Rahdin reititin hoitaa HTTPS:n. |
| **PersistentVolumeClaim (PVC)** | Pysyvä levy, joka säilyy podin vaihtuessa. Tässä esimerkissä H2-tietokannan tiedosto on PVC:llä. |
| **Secret / ConfigMap** | Salaisuudet (avaimet, salasanat) ja asetukset, jotka annetaan kontille ympäristömuuttujina tai tiedostoina. |

## 2. oc:n asennus ja kirjautuminen

### Kuka pääsee Rahtiin?

Rahdin käyttöön tarvitaan **CSC-käyttäjätunnus** ja **CSC-projekti, jolle Rahti-palvelu on
otettu käyttöön** ([CSC: Access to Rahti](https://docs.csc.fi/cloud/rahti/get-started/access/)).

- **Tällä kurssilla:** toistaiseksi Rahti-projekti ja käyttöoikeudet ovat vain opettajalla.
  Tunnilla kirjaudutaan **opettajan toimittamalla access tokenilla** (ks. alla), eikä omaa
  CSC-tunnusta tarvita.
- **Jos haluat oman projektin:** korkeakouluopiskelija voi kirjautua
  [MyCSC:hen](https://my.csc.fi) Haka-tunnuksilla ja luoda itselleen **opiskelijaprojektin**
  (*Student project*). Se on tarkoitettu kurssi- ja opinnäytetöihin, ja se on voimassa enintään
  6 kuukautta. Projektiin lisätään palveluksi Rahti (*Apply for access*). Ks.
  [CSC: How to create a new project](https://docs.csc.fi/accounts/how-to-create-new-project/).
  Rahdin käyttö kuluttaa projektin laskutusyksiköitä (*Billing Units*,
  [Rahti billing](https://docs.csc.fi/cloud/rahti/get-started/billing/)).

**Tunnilla yhteinen projekti:** kaikki käyttävät samaa projektia, joten nimeä omat resurssisi
yksilöllisesti. Korvaa ohjeen komennoissa `hellodb` esim. muotoon `hellodb-etunimi`
(nimi: pienet kirjaimet, numerot ja väliviivat). Älä poista tai muuta muiden resursseja.

### Asennus ilman kirjautumista (Linux, WSL2, macOS, Windows)

Rahdin konsolin latussivu (<https://console.rahti.csc.fi/command-line-tools>) vaatii
kirjautumisen. Saman `oc`-työkalun saa kuitenkin ilman tunnuksia Red Hatin julkiselta
peilipalvelimelta: <https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/>.

Valitse Rahdin versiota vastaava kanava. Marraskuussa 2026 Rahti käyttää OpenShift 4.22:ta,
joten käytä kansiota `stable-4.22`. Kansiossa `stable` on jo oc 5.x, jonka yhteensopivuutta
Rahdin kanssa ei ole testattu.

**Linux ja Windowsin WSL2 (Ubuntu tms.)** – WSL2:ssa ajetaan tavallinen Linux-versio:

```bash
cd /tmp
curl -LO https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable-4.22/openshift-client-linux.tar.gz
mkdir -p ~/.local/bin
tar -xzf openshift-client-linux.tar.gz -C ~/.local/bin oc kubectl
oc version --client
```

Jos `oc`-komentoa ei löydy, lisää `~/.local/bin` PATHiin: `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc`
ja avaa uusi terminaali. Ubuntussa hakemisto on PATHissa automaattisesti, jos se on olemassa
kirjautumishetkellä.

**Muut käyttöjärjestelmät** (samasta kansiosta):

| Käyttöjärjestelmä | Tiedosto |
|---|---|
| Windows (PowerShell / cmd) | `openshift-client-windows.zip`. Pura `oc.exe` esim. kansioon `C:\tools` ja lisää se PATHiin. |
| macOS, Apple Silicon (M1–M4) | `openshift-client-mac-arm64.tar.gz` |
| macOS, Intel | `openshift-client-mac.tar.gz` |

Älä käytä Linux-distribuutioiden pakettivarastojen vanhoja paketteja (esim. Fedoran
`origin-clients` on oc 3.x).

Lisätietoa: [CSC: Command line tool usage](https://docs.csc.fi/cloud/rahti/get-started/cli/)
ja [Red Hat: Getting started with the OpenShift CLI](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/cli_tools/openshift-cli-oc).

### Kirjautuminen tunnilla: opettajan antama token

Opettaja jakaa tunnilla kirjautumiskomennon:

```bash
oc login --token=<opettajan antama token> --server=https://api.2.rahti.csc.fi:6443
oc project ltitest
```

**Token on salasana.** Älä laita sitä git-repoon, Discordiin, kuvakaappauksiin, muistiinpanoihin
tai ohjeisiin. Token on voimassa rajatun ajan (tyypillisesti tunnin ajan). Kun se vanhenee,
komennot antavat virheen `error: You must be logged in to the server (Unauthorized)`.

```bash
$ oc whoami          # kuka olen (palvelutilin token näyttää system:serviceaccount:…)
$ oc project ltitest # valitse projekti, johon seuraavat komennot kohdistuvat
Already on project "ltitest" on server "https://api.2.rahti.csc.fi:6443".
```

### Kirjautuminen omalla CSC-tunnuksella (jos sinulla on oma projekti)

Avaa Rahdin web-konsolissa oikean yläkulman käyttäjävalikosta **Copy login command** →
**Display Token**, ja kopioi komento terminaaliin. Henkilökohtainen token vanhenee noin
vuorokaudessa.

Uusi Rahti-projekti (namespace) luodaan helpoimmin web-konsolissa, koska kuvaukseen on
merkittävä CSC-projektin numero (`csc_project: 200xxxx`). Komentoriviltä se onnistuu näin:

```bash
oc new-project oma-projekti --description="csc_project: 2001234"
```

### Opettajalle: tunnin token palvelutilillä

Älä jaa omaa henkilökohtaista tokeniasi. Se antaa pääsyn kaikkiin projekteihisi ja toimii
sinun nimissäsi. Tee sen sijaan projektiin palvelutili, jolla on oikeudet vain tähän projektiin,
ja luo sille määräaikainen token:

```bash
oc project ltitest
oc create serviceaccount opiskelijat
oc policy add-role-to-user edit -z opiskelijat      # saa luoda/muuttaa/poistaa resursseja tässä projektissa
oc create token opiskelijat --duration=4h           # tulostaa tokenin, jaa se opiskelijoille
```

Tunnin jälkeen voit mitätöidä kaikki tokenit poistamalla palvelutilin:
`oc delete serviceaccount opiskelijat`. Palvelin voi rajoittaa tokenin enimmäiskestoa.

## 3. oc:n peruskomennot

| Komento | Mitä tekee |
|---|---|
| `oc status` | Projektin yleiskuva: mitä ajetaan ja mistä se on rakennettu. |
| `oc get all` | Listaa podit, servicet, deploymentit, buildit, imagestreamit ja routet. |
| `oc get pods` / `oc get pods -w` | Podit (`-w` seuraa muutoksia, lopetus Ctrl-C). |
| `oc get pvc,route,secret` | Muut resurssit pilkuilla eroteltuina. |
| `oc describe pod <nimi>` | Yksityiskohdat ja **Events**: miksi pod ei käynnisty, eikö image löydy, onko muisti loppunut… |
| `oc logs deployment/hellodb` | Sovelluksen loki (Springin konsolituloste). `-f` seuraa lokia. |
| `oc logs -f bc/hellodb` | Viimeisimmän buildin loki. |
| `oc exec deployment/hellodb -- ls -la /data` | Aja komento kontissa. |
| `oc rsh deployment/hellodb` | Avaa shell konttiin. |
| `oc port-forward deployment/hellodb 8080:8080` | Ohjaa podin portin omalle koneelle (`http://localhost:8080`) ilman julkista routea. |
| `oc set env deployment/hellodb NIMI=arvo` | Aseta ympäristömuuttuja (aiheuttaa uudelleenkäynnistyksen). |
| `oc set env deployment/hellodb --list` | Näytä ympäristömuuttujat. |
| `oc rollout status deployment/hellodb` | Odota, että uusi versio on käynnissä. |
| `oc rollout restart deployment/hellodb` | Käynnistä podit uudelleen. |
| `oc rollout undo deployment/hellodb` | Palaa edelliseen versioon. |
| `oc scale deployment/hellodb --replicas=0` | Pysäytä sovellus (ei kuluta resursseja). Käynnistys: `--replicas=1`. |
| `oc delete all -l app=hellodb` | Poista sovelluksen resurssit labelin perusteella. |
| `oc explain deployment.spec.strategy` | Dokumentaatio mille tahansa kentälle. |
| `oc get deployment/hellodb -o yaml` | Resurssin koko määrittely YAML-muodossa. |

Esimerkki: mitä projektissa on käynnissä?

```text
$ oc get pods
NAME                           READY   STATUS      RESTARTS   AGE
hello-world-69444ff77c-pbfn6   1/1     Running     0          2d
hellodb-1-build                0/1     Completed   0          5m
hellodb-79d7cb7448-547w2       1/1     Running     0          24s
```

`*-build`-podit ovat valmiita buildeja (`Completed`). Ne eivät kuluta resursseja.

## 4. Miten konttien buildaus tehdään

Rahtiin saa konttikuvan kolmella tavalla:

| Tapa | Komennot | Milloin |
|---|---|---|
| **A. Binary Docker build Rahdissa** (käytetty tässä ohjeessa) | `oc new-build --strategy=docker --binary` + `oc start-build --from-dir=.` | Lähdekoodi on omalla koneella. Dockeria tai Podmania ei tarvita, eikä koodin tarvitse olla Gitissä. |
| **B. Git-build Rahdissa** | `oc new-build https://github.com/käyttäjä/repo.git --strategy=docker` | Koodi on julkisessa Git-repossa. `oc start-build` hakee aina uusimman commitin, ja webhookilla buildi voi käynnistyä automaattisesti pushista. |
| **C. Build omalla koneella + push** | `podman build` + `podman push image-registry.apps.2.rahti.csc.fi/...` | Image halutaan testata paikallisesti ennen julkaisua, tai buildi on raskas. |

Lisäksi on S2I (Source-to-Image), jossa Rahti rakentaa Java-sovelluksen ilman Dockerfileä
valmiilla builder-imagella. Dockerfile on kuitenkin läpinäkyvämpi ja toimii samoin kaikkialla,
joten tässä käytetään sitä.

### Miten tämä tehtiin testiprojektissa

Ennen tätä ohjetta Rahdin testiprojektiin vietiin uudempi Spring Boot -sovellus
(Spring Boot 4 / Java 25) tavalla **A**:

1. Projektin juureen **monivaiheinen Dockerfile**:
   - vaihe 1: `maven:3-eclipse-temurin-25` kääntää jarin;
   - vaihe 2: `eclipse-temurin:25-jre` ajaa sen;
   - lopullinen image sisältää vain JRE:n ja jarin, ei Mavenia eikä lähdekoodia.
2. `.dockerignore`, jotta `target/`, `.git/` ja avaintiedostot eivät lähde buildiin.
3. Rahtiin luotiin binary build ja käynnistettiin se kansiosta:

   ```bash
   oc new-build --name=testisovellus --strategy=docker --binary --labels=app=testisovellus
   oc start-build testisovellus --from-dir=. --follow
   ```

   `--from-dir=.` pakkaa kansion (pois lukien `.dockerignore`-tiedostot) ja lähettää sen
   Rahtiin. Rahti ajaa Dockerfilen omalla build-podillaan ja vie valmiin imagen
   ImageStreamiin `testisovellus:latest`.
4. Sovellus käynnistettiin ImageStreamista komennolla `oc new-app --image-stream=testisovellus:latest`.
   Asetukset annettiin ympäristömuuttujina (`oc set env`) ja salainen avain Secretinä
   (`oc create secret generic … --from-file=…`), ei imagen sisällä.
5. Lisättiin resurssirajat, terveystarkistukset (Spring Actuatorin `/actuator/health/*`)
   ja HTTPS-route.
6. Jokainen päivitys on yksi komento, `oc start-build testisovellus --from-dir=. --follow`:
   uusi image käynnistää uuden version automaattisesti.

Tässä ohjeessa tehdään sama JDK 11:llä ja vanhemmalle Spring Bootille.

## 5. Esimerkki: JDK 11 -kontti olemassa olevasta Spring-sovelluksesta

Lähtötilanne: tavallinen Maven-projekti (`pom.xml`, `src/`), joka käynnistyy
`mvn spring-boot:run`-komennolla. Sovellukseen **ei tarvitse muuttaa riviäkään koodia**:
lisätään vain `Dockerfile` ja `.dockerignore`. Rahtia varten tarvittavat asetukset annetaan
ympäristömuuttujina.

Sovelluksesta kannattaa tarkistaa etukäteen:

- **Java-versio:** `pom.xml` kääntää Java 8 -tasolle (`maven.compiler.source 1.8`). JDK 11
  kääntää ja ajaa sen ongelmitta, ja Spring Boot 2.1 tukee Java 11:tä.
- **Tiedostoon kirjoittaminen:** `application.properties` sisältää rivin
  `spring.datasource.url=jdbc:h2:file:./database`, eli H2 kirjoittaa tietokannan
  työhakemistoon. Kontissa hakemiston on oltava kirjoitettava, ja jos datan halutaan säilyvän,
  sen on oltava pysyvällä levyllä (kohta 5.5).
- **Portti:** Spring Boot kuuntelee oletuksena porttia 8080, ja Rahti olettaa saman.

### 5.1 Dockerfile

Tiedosto `Dockerfile` (repon juuressa):

```dockerfile
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
```

Tärkeimmät kohdat:

| Rivi | Miksi |
|---|---|
| `maven:3.9-eclipse-temurin-11` | Maven ja JDK 11 valmiina. Omalla koneella ei tarvita JDK 11:tä eikä Mavenia. |
| `COPY pom.xml` + `dependency:go-offline` ennen `COPY src` | Riippuvuuksien lataus on oma kerroksensa, joten koodimuutos ei lataa koko Maven-repoa uudelleen. Hyöty näkyy etenkin paikallisissa buildeissa. |
| `-DskipTests` | Tämän projektin TMC- ja Selenium-testejä ei ajeta kontissa. Aja ne omalla koneella (`mvn test`). |
| Kaksi `FROM`-riviä | Monivaiheinen buildi: lopullisessa imagessa on vain JRE ja jar (noin 420 Mt). Mavenia, JDK:ta ja lähdekoodia ei ole mukana. |
| `chgrp -R 0 … && chmod -R g=u …` | **Rahti-spesifi:** kontti ajetaan satunnaisella käyttäjällä (esim. `uid=1010640000`), joka on aina ryhmässä 0 (root-ryhmä). Ilman tätä H2 ei voisi kirjoittaa tiedostoaan. |
| `ENV SPRING_DATASOURCE_URL=…` | Spring Bootin *relaxed binding*: ympäristömuuttuja `SPRING_DATASOURCE_URL` ohittaa `application.properties`-tiedoston arvon `spring.datasource.url`. Näin minkä tahansa asetuksen voi muuttaa koskematta koodiin. |
| `-XX:MaxRAMPercentage=75` | JVM käyttää enintään 75 % kontin muistirajasta. Loppu jää metaspacelle, säikeille ja muulle, eikä kontti kaadu muistin loppumiseen (OOMKilled). |
| `USER 1001` | Imagea ei ajeta rootina myöskään paikallisesti. Rahti ohittaa tämän omalla UID:llään. |
| `ENTRYPOINT java -jar` | Spring Bootin "fat jar" sisältää kaiken, myös Tomcatin. |

`spring-boot-devtools` (pom.xml:ssä `runtime`-scopella) jää pois valmiista jarista
automaattisesti, joten se ei ole tuotantokontissa mukana.

### 5.2 .dockerignore

```text
target/
.git/
*.md
database*.db
*.mv.db
*.trace.db
```

Tämä estää paikallisen `target/`-kansion, Gitin ja **paikallisen tietokantatiedoston**
lähtemisen buildiin. Muuten omat testitunnuksesi päätyisivät imageen.

### 5.3 (Valinnainen) testaus omalla koneella Podmanilla

```bash
podman build -t hellodb:test .
# --user 54321:0 matkii Rahtia: satunnainen UID ryhmässä 0
podman run --rm --name hellodb-test --user 54321:0 -p 18080:8080 hellodb:test
```

Avaa toisessa terminaalissa tai selaimessa <http://localhost:18080/accounts>, luo tunnus ja kirjaudu.
Tulokset testiajosta:

```text
login page: 200
create account: 302
$ podman exec hellodb-test ls -la /data
-rw-r--r--+ 1 54321 root 20480 Nov 19 06:10 database.mv.db
Started HelloDbAuthenticationApplication in 5.321 seconds
```

Rootless Podmanilla UID:n täytyy olla käyttäjän alias-alueella (esim. 54321).
Hyvin suuri UID kuten `1234567` antaa virheen `setresuid … Invalid argument`.

### 5.4 Buildaus Rahdissa

Aja komennot repon juurihakemistossa:

```bash
git clone https://github.com/mjpanula/docker-spring-intro.git
cd docker-spring-intro
```

Sitten:

```bash
oc project ltitest

# Luo BuildConfig + ImageStream "hellodb" (kerran)
oc new-build --name=hellodb --strategy=docker --binary --labels=app=hellodb

# Lähetä kansio Rahtiin ja aja Dockerfile siellä
oc start-build hellodb --from-dir=. --follow
```

Tuloste (lyhennetty):

```text
    * A Docker build using binary input will be created
      * The resulting image will be pushed to image stream tag "hellodb:latest"
--> Creating resources with label app=hellodb ...
    imagestream.image.openshift.io "hellodb" created
    buildconfig.build.openshift.io "hellodb" created
--> Success
Uploading directory "." as binary input for the build ...
build.build.openshift.io/hellodb-1 started
[1/2] STEP 1/6: FROM docker.io/library/maven:3.9-eclipse-temurin-11 AS build
...
[2/2] STEP 8/10: ENTRYPOINT ["java","-jar","/app/app.jar"]
Successfully pushed image-registry.openshift-image-registry.svc:5000/ltitest/hellodb@sha256:8e08…
Push successful
```

Buildi kesti tässä noin 3,5 minuuttia, koska Maven lataa kaikki riippuvuudet.
Binary buildissa Rahdin build-pod aloittaa joka kerta tyhjästä, joten riippuvuudet ladataan
uudelleen jokaisella buildilla.

### 5.5 Sovelluksen käynnistys, levy, resurssit, terveystarkistukset ja route

```bash
# 1. Deployment + Service ImageStreamista
oc new-app --image-stream=hellodb:latest --name=hellodb

# 2. Resurssit. Rahdin LimitRange: CPU:n limit/request-suhde saa olla enintään 5.
oc set resources deployment/hellodb --requests=cpu=200m,memory=384Mi --limits=cpu=1,memory=512Mi

# 3. Recreate-strategia: vanha pod sammuu ennen kuin uusi käynnistyy.
#    Pakollinen, koska RWO-levy ja H2-tiedosto eivät kestä kahta podia yhtä aikaa.
oc patch deployment/hellodb -p '{"spec":{"strategy":{"type":"Recreate","rollingUpdate":null}}}'

# 4. Pysyvä levy (PVC, 1 Gi) hakemistoon /data, jonne H2 kirjoittaa
oc set volume deployment/hellodb --add --name=data --type=pvc \
   --claim-name=hellodb-data --claim-size=1Gi --claim-mode=ReadWriteOnce --mount-path=/data

# 5. Terveystarkistukset. Sovelluksessa ei ole Actuatoria, joten käytetään /login-sivua,
#    joka vastaa 200 ilman kirjautumista.
oc set probe deployment/hellodb --readiness --get-url=http://:8080/login --initial-delay-seconds=10
oc set probe deployment/hellodb --liveness  --get-url=http://:8080/login --initial-delay-seconds=60

# 6. Julkinen HTTPS-osoite. http:// ohjataan https://-osoitteeseen.
oc create route edge hellodb --service=hellodb --port=8080-tcp --insecure-policy=Redirect

# 7. Spring Boot 2.1 ei luota oletuksena reitittimen X-Forwarded-Proto-otsakkeeseen,
#    vaan tekee uudelleenohjaukset (esim. /login) http://-osoitteisiin. Korjaus:
oc set env deployment/hellodb SERVER_USE_FORWARD_HEADERS=true

oc rollout status deployment/hellodb
oc get route hellodb
```

Tuloste (lyhennetty):

```text
--> Found image 853b2b7 (20 seconds old) in image stream "ltitest/hellodb" under tag "latest"
--> Creating resources ...
    deployment.apps "hellodb" created
    service "hellodb" created
--> Success
deployment.apps/hellodb resource requirements updated
deployment.apps/hellodb patched
deployment.apps/hellodb volume updated
deployment.apps/hellodb probes updated
deployment.apps/hellodb probes updated
route.route.openshift.io/hellodb created
deployment.apps/hellodb updated
Waiting for deployment "hellodb" rollout to finish: 0 of 1 updated replicas are available...
deployment "hellodb" successfully rolled out
NAME      HOST/PORT                       PATH   SERVICES   PORT       TERMINATION     WILDCARD
hellodb   hellodb-ltitest.2.rahtiapp.fi          hellodb    8080-tcp   edge/Redirect   None
```

Routen osoite on muotoa `<nimi>-<projekti>.2.rahtiapp.fi`.

**Huom (Spring Boot 2.2 ja uudemmat):** asetus `server.use-forward-headers` korvattiin
asetuksella `server.forward-headers-strategy`. Uusissa sovelluksissa käytä
`oc set env deployment/<nimi> SERVER_FORWARD_HEADERS_STRATEGY=native`.

### 5.6 Tarkistus

Selaimella: <https://hellodb-ltitest.2.rahtiapp.fi/accounts> → luo tunnus → kirjaudu →
kirjoita viesti. Saman voi tehdä komentoriviltä:

```bash
U=https://hellodb-ltitest.2.rahtiapp.fi
curl -s -o /dev/null -w '%{http_code} %{redirect_url}\n' http://hellodb-ltitest.2.rahtiapp.fi/login
curl -s -o /dev/null -w '%{http_code}\n' -d 'username=rahtitesti&password=Testi-123' $U/accounts
curl -s -c keksit -b keksit -o /dev/null -w '%{http_code} %{redirect_url}\n' \
     -d 'username=rahtitesti&password=Testi-123' $U/login
curl -s -c keksit -b keksit -o /dev/null -d 'content=Terveisiä Rahdista' $U/messages
curl -s -b keksit $U/messages | grep 'Terveisiä Rahdista'
```

```text
302 https://hellodb-ltitest.2.rahtiapp.fi/login        ← http ohjautuu https:ään
302                                                     ← tunnus luotu
302 https://hellodb-ltitest.2.rahtiapp.fi/              ← kirjautuminen onnistui
Terveisiä Rahdista                                      ← viesti tallessa
```

**Pysyvyyden testaus:** `oc set env` (kohta 5.5:n 7. askel) käynnisti uuden podin.
Viesti oli edelleen tallessa, eli tietokanta on PVC:llä eikä podin väliaikaisella levyllä:

```text
$ oc exec deployment/hellodb -- sh -c 'id; ls -la /data'
uid=1010640000(1010640000) gid=0(root) groups=0(root),1010640000(1010640000)
-rw-rw-r--+ 1 1010640000 1010640000 36864 Nov 19 06:27 database.mv.db
drwxrws---+ 2 root       1010640000 16384 Nov 19 06:26 lost+found
```

Tulosteesta näkyy myös Rahdin satunnainen UID (1010640000) ja ryhmä 0.

Lokin tarkistus:

```text
$ oc logs deployment/hellodb | grep -E 'Started|Picked'
Picked up JAVA_TOOL_OPTIONS: -XX:MaxRAMPercentage=75 -Djava.io.tmpdir=/tmp
... Started HelloDbAuthenticationApplication in 11.243 seconds (JVM running for 12.101)
```

## 6. Sovelluksen päivitys

Kun koodi muuttuu:

```bash
oc start-build hellodb --from-dir=. --follow
```

Uusi image päivittää ImageStreamin `hellodb:latest`, ja Deployment vaihtaa uuteen versioon
automaattisesti (Recreate: hetken katko). Seuraa päivitystä: `oc rollout status deployment/hellodb`.
Jos jokin menee rikki: `oc rollout undo deployment/hellodb`.

### Vaihtoehto: build omalla koneella ja push Rahtiin (tapa C)

```bash
podman login -u unused -p "$(oc whoami -t)" image-registry.apps.2.rahti.csc.fi
podman build -t image-registry.apps.2.rahti.csc.fi/ltitest/hellodb:latest .
podman push image-registry.apps.2.rahti.csc.fi/ltitest/hellodb:latest
```

Push päivittää saman ImageStreamin, joten Deployment päivittyy samalla tavalla.

## 7. Sudenkuopat

| Oire | Syy ja korjaus |
|---|---|
| Rollout jää jumiin, ja `oc describe` tai `oc get events` kertoo `cpu max limit to request ratio per Container is 5` | Rahdin LimitRange: `limits.cpu / requests.cpu ≤ 5`. Esim. request 200m + limit 1 käy, request 100m + limit 1 ei käy. |
| Pod kaatuu, ja lokissa on `Permission denied` tai `AccessDeniedException` | Kontti ajetaan satunnaisella UID:llä. Kirjoitettaville hakemistoille `chgrp -R 0 … && chmod -R g=u …` Dockerfilessä, tai kirjoita `/tmp`:hen tai PVC:lle. |
| Tiedot katoavat uudelleenkäynnistyksessä | Podin levy on väliaikainen. Käytä PVC:tä (`oc set volume --add --type=pvc …`) tai oikeaa tietokantaa (esim. PostgreSQL Rahdissa tai CSC:n Pukki DBaaS). |
| Uusi pod jää tilaan `ContainerCreating` / `Multi-Attach error` | RWO-levy voi olla kiinni vain yhdessä podissa kerrallaan. Käytä `Recreate`-strategiaa (kohta 5.5:n 3. askel). |
| Pod tilassa `OOMKilled` / `CrashLoopBackOff` | Muisti loppui. Nosta `--limits=memory=…` tai pienennä `MaxRAMPercentage`. Spring Boot tarvitsee käytännössä vähintään 384–512 Mi. |
| Pod käynnistyy uudelleen jatkuvasti, vaikka loki näyttää normaalilta | Liveness-tarkistus iski ennen kuin Spring ehti käynnistyä. Kasvata `--initial-delay-seconds`. |
| Kirjautumisen jälkeen ohjaus `http://`-osoitteeseen | Spring ei tiedä olevansa HTTPS-proxyn takana: `SERVER_USE_FORWARD_HEADERS=true` (Boot 2.1) / `SERVER_FORWARD_HEADERS_STRATEGY=native` (Boot ≥ 2.2). |
| Buildissa `release version 11 not supported` tai `25 not supported` | Paikallisesti: koneessa on vain JRE, ei JDK:ta (Fedorassa `java-XX-openjdk-devel`). Kontissa tätä ei tapahdu, koska Maven-image sisältää JDK:n. |
| `error: You must be logged in to the server (Unauthorized)` | Token vanheni. Kirjaudu uudelleen (`oc login --token=…`). |
| `oc start-build` lähettää satoja megatavuja | `.dockerignore` puuttuu, ja `target/` tai `.git/` lähtee mukaan. |

**Tietoturvahuomio tästä esimerkistä:**
- Sovelluksen `/accounts`-sivu on avoin kaikille (`permitAll`), joten kuka tahansa voi luoda
  tunnuksen julkiseen osoitteeseen.
- Sovelluksessa on myös `csrf().disable()`.
- Spring Boot 2.1 ja Java 11 ovat vanhoja, eikä niihin enää tule tietoturvapäivityksiä.

Opetusesimerkkinä tämä käy, mutta pidä sovellus käynnissä vain tarvittaessa
(`oc scale deployment/hellodb --replicas=0`).

## 8. Siivous

`oc set volume` ja `oc create route` eivät lisää resursseihin `app=hellodb`-labelia,
joten ne poistetaan erikseen:

```bash
oc delete all,imagestream,buildconfig -l app=hellodb
oc delete route hellodb
oc delete pvc hellodb-data          # HUOM: poistaa tietokannan pysyvästi
```

## 9. Komentojen pikaopas

```bash
# kerran
oc login --token=… --server=https://api.2.rahti.csc.fi:6443
oc project ltitest
oc new-build --name=hellodb --strategy=docker --binary --labels=app=hellodb
oc start-build hellodb --from-dir=. --follow
oc new-app --image-stream=hellodb:latest --name=hellodb
oc set resources deployment/hellodb --requests=cpu=200m,memory=384Mi --limits=cpu=1,memory=512Mi
oc patch deployment/hellodb -p '{"spec":{"strategy":{"type":"Recreate","rollingUpdate":null}}}'
oc set volume deployment/hellodb --add --name=data --type=pvc --claim-name=hellodb-data --claim-size=1Gi --mount-path=/data
oc set probe deployment/hellodb --readiness --get-url=http://:8080/login --initial-delay-seconds=10
oc set probe deployment/hellodb --liveness  --get-url=http://:8080/login --initial-delay-seconds=60
oc create route edge hellodb --service=hellodb --port=8080-tcp --insecure-policy=Redirect
oc set env deployment/hellodb SERVER_USE_FORWARD_HEADERS=true

# päivitys
oc start-build hellodb --from-dir=. --follow

# vianetsintä
oc get pods
oc logs -f deployment/hellodb
oc describe pod <pod>
oc get events --sort-by=.lastTimestamp
oc rsh deployment/hellodb
```

# Logg

Nyaste överst. En post per genomgånget material.

---

## 2026-08-19  Terraform Basics, arbetsflödet och state

**Underlag**
`[HashiCorp; Terraform Basics; https://youtu.be/_45W3Z8XWL4]`
21:20, skärminspelning med kod och terminal. Presenteras av Nicholas Jackson.
Exempelkod på `https://github.com/nicholasjackson/demo-terraform-basics`.

### Genomgånget innehåll

**00:19 Öppningsdemo mot Google Cloud**
Videon börjar i andra änden än den föregående. En `vm.tf` visas med en resurs av
typen `google_compute_instance` som heter `ollama`, med maskintyp vald via en
variabel, zon, projekt, en boot disk som refererar till en `google_compute_disk`
och ett `metadata`-block med ssh-nycklar. Ett `terraform apply` skapar
servicekonton och den virtuella maskinen, installerar NVIDIA-drivrutiner och
Docker och sätter upp en egen AI-assistent mot Ollama. Maskinen syns sedan i
Google-konsolen som `ollama`, `g2-standard-4`, zon `europe-west1-b`, och
webbgränssnittet går att logga in i med ett lösenord som konfigurationen
genererat.

**02:47 Nedrivning som städning**
Innan resten av genomgången rivs demot med `terraform destroy`. Kommandot pratar
med Google Cloud och tar bort allt som konfigurationen definierar, vilket
kontrolleras i konsolen. Poängen som görs är att experiment inte ska ligga kvar
och kosta pengar.

**03:32 Installing Terraform**
Installationsanvisningarna ligger på `developer.hashicorp.com`. Det går via
pakethanterare som Brew på macOS, via binärer för Windows, macOS, Linux och BSD,
eller via pakethanterare på Linux. I videon hämtas amd64-binären med `curl` till
`terraform.zip` och installeras för hand.

```console
$ unzip terraform.zip
Archive:  terraform.zip
  inflating: LICENSE.txt
  inflating: terraform

$ ls
LICENSE.txt  docker.tf  main.tf  terraform  terraform.zip

$ sudo mv ./terraform /usr/local/bin

$ terraform version
Terraform v1.9.0
```

Flytten sker till `/usr/local/bin` eftersom den katalogen ligger i PATH, alltså
går binären att köra från vilken mapp som helst.

**05:19 Example Repository**
Exempelrepot har fyra mappar, `aws`, `azure`, `gcp` och `basics`. Genomgången
använder bara `basics`, som innehåller `main.tf` och `docker.tf`. De skapar
Docker-containrar på den egna maskinen, alltså går det att öva utan att göra fel
i en molnmiljö och utan att något kostar.

**05:59 Terraform Configuration, main.tf**
`main.tf` innehåller `terraform`-blocket som talar om vilka providers
konfigurationen behöver, samt själva providerblocket.

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {}
```

En provider är översättningslagret mellan HCL-resurserna och ett API, i det här
fallet Dockers.

**06:36 Terraform Configuration, docker.tf**
`docker.tf` definierar två resurser. Nyckelordet `resource` deklarerar en sak som
ska skapas. Kommentarerna i filen visar vad varje resurs motsvarar som
Docker-kommando för hand.

```hcl
// This is the same as doing:
// docker pull hashicorp/vault:1.12.6
resource "docker_image" "vault" {
  name = "hashicorp/vault:1.12.6"
}

// This is the same as doing:
// docker run -p 8200:8200 --name "terraform-basics-vault" hashicorp/vault:1.12.6
resource "docker_container" "vault" {
  name  = "terraform-basics-vault"
  image = docker_image.vault.image_id

  ports {
    internal = 8200
    external = 8200
  }
}
```

**07:20 Referenser skapar ordningen**
Containern anger inte imagenamnet direkt utan pekar på
`docker_image.vault.image_id`. Genom referensen förstår Terraform att imagen
måste finnas innan containern kan skapas. Det finns ingen betydelse i vilken
ordning resurserna står eller vilken fil de ligger i, beroendegrafen räknas fram
ur referenserna.

**07:45 terraform init**
`init` läser konfigurationen i den aktuella mappen och hämtar de plugins som
behövs från Terraform-registryt.

```console
$ terraform init
Initializing the backend...
Initializing provider plugins...
- Finding kreuzwerker/docker versions matching "3.0.2"...
```

Efter körningen finns `.terraform` och `.terraform.lock.hcl` i mappen.

**08:17 terraform plan**
`plan` analyserar resurserna i konfigurationen, jämför mot vad som redan finns och
redovisar skillnaden. Eftersom ingenting är skapat än ska allt skapas.

```console
$ terraform plan

  # docker_image.vault will be created
  + resource "docker_image" "vault" {
      + id          = (known after apply)
      + image_id    = (known after apply)
      + name        = "hashicorp/vault:1.12.6"
      + repo_digest = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

Värden som Terraform redan känner till skrivs ut, exempelvis namnet på imagen.
Värden som bara Docker kan svara på står som `(known after apply)`.

**09:51 terraform apply**
`apply` skapar resurserna. Som säkerhetskontroll visas alltid planen först och
körningen stannar på frågan `Do you want to perform these actions?` där `yes`
krävs. Efteråt kontrolleras resultatet mot Docker direkt.

```console
$ docker ps
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS        PORTS                    NAMES
0037ecb7c340   af3d918416ba   "docker-entrypoint.s…"   8 seconds ago   Up 6 seconds  0.0.0.0:8200->8200/tcp   terraform-basics-vault

$ curl localhost:8200/v1/sys/health | jq
{
  "initialized": true,
  "sealed": false,
  "standby": false,
  "performance_standby": false,
  "replication_performance_mode": "disabled",
  "replication_dr_mode": "disabled",
  "server_time_utc": 1720094513,
  "version": "1.12.6",
  "cluster_name": "vault-cluster-7f6244b7",
  "cluster_id": "42cedf4b-738c-4713-82a1-3045c9fe183e"
}
```

**11:20 Updating Resources**
Imagen ändras i konfigurationen från `hashicorp/vault:1.12.6` till
`hashicorp/vault:1.17.1`. Vid nästa `apply` blir svaret inte en uppdatering utan
en ersättning, eftersom vissa resurstyper inte går att ändra på plats.

```console
  # docker_image.vault must be replaced
-/+ resource "docker_image" "vault" {
      ~ id          = "sha256:af3d918416…hashicorp/vault:1.12.6" -> (known after apply)
      ~ image_id    = "sha256:af3d918416…" -> (known after apply)
      ~ name        = "hashicorp/vault:1.12.6" -> "hashicorp/vault:1.17.1" # forces replacement
      ~ repo_digest = "hashicorp/vault@sha256:2517235f06…" -> (known after apply)
    }

Plan: 2 to add, 0 to change, 2 to destroy.
```

Containern måste bytas i sin tur eftersom den beror på imagen. Terraform tar bort
den gamla containern, hämtar den nya imagen och skapar containern igen. Samma
kontroll med `curl` och `jq` visar sedan version 1.17.1.

**14:00 Nedrivning i arbetsflödet**
`terraform destroy` tar bort de resurser som skapats av konfigurationen. Även här
visas en plan först, `2 to destroy`, och ett `yes` krävs. Samma provider används
som vid `apply`, fast åt andra hållet. Efteråt är `docker ps` tom. Arbetsflödet som
helhet är alltså definiera konfiguration, `init`, `plan`, `apply` och sist
nedrivningen. Poängen som görs är att resultatet blir detsamma varje gång `apply`
körs.

**15:26 Terraform State**
Resurserna skapas om, den här gången med `terraform apply -auto-approve` som
svarar ja automatiskt. Det beskrivs som en bekvämlighet som inte hör hemma i
produktion. Efteråt innehåller mappen `docker.tf`, `main.tf`,
`terraform.tfstate` och `terraform.tfstate.backup`.

**16:21 Vad state-filen är**
State-filen är där Terraform lagrar vad den faktiskt har skapat. Den är JSON och
innehåller `lineage`, `outputs` och en lista `resources`, där varje post har
`mode`, `type`, `name`, `provider` och `instances` med alla attribut som resursen
fick. För containern syns exempelvis `id`, `image`, `name`, `ip_address` och
`network_mode`.

**16:52 State är jämförelsepunkten**
Om ett värde ändras i state-filen, exempelvis namnet från
`terraform-basics-vault` till `terraform-basics-vaults`, kommer ett `terraform
plan` att rapportera en ändring. Terraform jämför alltså konfigurationen mot
state, inte mot verkligheten direkt.

**17:38 Var state ligger**
I exemplet ligger state lokalt på disk. Det går också att lagra remote, i
Terraform Cloud, i en S3-bucket, i cloud storage eller i Terraform Enterprise.
Remote är rekommendationen för produktionskonfigurationer. Detaljerna lämnas till
ett senare, mer avancerat material.

**18:00 Inspektera state från CLI**
`terraform show` skriver ut hela state. Med två resurser är det överskådligt, men
i en större konfiguration med hundratals resurser blir utskriften oanvändbar.
Därför finns `terraform state` med underkommandon för att lista resurser, flytta
poster och hantera remote state.

```console
$ terraform state list
docker_container.vault
docker_image.vault

$ terraform state show docker_container.vault
    network_mode      = "default"
    remove_volumes    = true
    restart           = "no"
    runtime           = "runc"
    shm_size          = 64
    start             = true
    wait_timeout      = 60

    ports {
        external = 8200
        internal = 8200
        ip       = "0.0.0.0"
        protocol = "tcp"
    }
```

**19:58 Summary**
Sammanfattningen tar upp providers som gränssnitt mot API, konfiguration som sätt
att skapa resurser, hur Terraform upptäcker ändringar och avgör om en resurs kan
uppdateras eller måste ersättas, samt hur nedrivningen städar. Nästa steg som
utlovas är en uppföljare som bygger den virtuella maskinen från öppningsdemot i
GCP, Azure eller AWS.

### Täcker från förra posten

Luckorna som noterades efter `Introduction to Terraform` är delvis fyllda.
HCL-syntax finns nu med `terraform`-blocket, `required_providers`, `resource` och
`ports`. Kommandona `init`, `apply`, `show`, `state list` och `state show` är
visade i terminal, liksom nedrivningen, flaggan `-auto-approve` och noten om
`-out`. Begreppen provider, referens mellan resurser och lokalt state är
genomgångna med kod.

### Vad videon inte tar upp

Ingen `variable`, `output`, `local` eller `data source`, trots att öppningsdemot
använder `var.` på flera rader. Inget `count` eller `for_each`. Inget om moduler.
Ingen `terraform fmt`, `validate` eller `import`. Remote state och backend nämns
men konfigureras inte. Ingen `.tfvars`. Ingen genomgång av `terraform.lock.hcl`
utöver att filen dyker upp. Inget om workspaces och inget om policy as code.
Beroendegrafen förklaras genom referenser men `depends_on` nämns inte.

---


## 2026-08-18  Infrastructure as Code och Terraform

**Underlag**
`[HashiCorp; Introduction to Terraform; https://youtu.be/ZFLWA1kQ3ls]`
22:55, whiteboardformat, konceptuellt utan kod.

### Genomgånget innehåll

**00:29 Infrastructure as Code**
Utgångspunkten är att sluta hantera infrastruktur manuellt, alltså logga in i en
konsol, peka och klicka, köra kommandon för hand. I stället kodifieras
infrastrukturen. Den versionshanteras i git och får samma livscykel som en
applikations kod.

**01:06 HCL och resurser**
Terraform använder HCL, HashiCorp Configuration Language. Språket är deklarativt,
alltså beskriver man vilka resurser som ska finnas, inte stegen dit. En resurs är
i princip vad som helst som går att skapa, ändra eller ta bort.

**01:35 Exempelmiljön**
Genomgången utgår från en trelagersapplikation. En load balancer framför ett antal
virtuella maskiner som i sin tur pratar med en hanterad databas. I stället för att
sätta upp dem för hand beskrivs de i kod, storlek på databasen, image på maskinerna
och vilka maskiner load balancern pekar på.

**02:19 plan**
`plan` jämför önskat läge, alltså konfigurationen, med verkligt läge, alltså state,
och räknar fram en exekveringsplan. Planen visar vad som ska skapas, ändras och tas
bort innan något händer. Syftet är att den som kör ska veta exakt vad Terraform
tänker göra.

**03:08 apply**
`apply` verkställer planen och skriver ett nytt state. Man går från state ett till
state två.

**03:26 Day zero, tomt läge**
Utan befintlig infrastruktur är första planen enkel. Ingenting finns, allt ska
skapas. Terraform rapporterar att den skapar databasen, maskinerna och load
balancern, och efter körningen finns ett första state.

**03:56 Day two, ändringar i efterhand**
Nästa steg i exemplet är att lägga till en DNS-post, växla databasen från small
till medium och lägga till en fjärde virtuell maskin. Ändringarna görs i
konfigurationen, inte för hand i konsolen.

**04:45 Beroenden och sekvensering**
Planen blir genast mer komplex. DNS-posten är ny och skapas. Tre maskiner finns,
den fjärde skapas. Load balancern måste ändras eftersom den behöver känna till den
nya maskinen, och den ändringen kan inte ske förrän maskinen finns och har en
IP-adress. DNS-posten väntar i sin tur på load balancern. Databasen ändras från
small till medium. Terraform räknar ut ordningen och avbryter vid rätt steg om
något går fel.

**05:59 Infrastrukturens livscykel**
Infrastruktur är sällan klar vid första körningen. Day zero är grunden, alltså
konto, landing zone, virtuella nätverk och de första skyddsräckena. Day one är
första deployen av infrastruktur och applikation. Day two och framåt är hela
resten av livet fram till avveckling.

**08:00 Day two plus i praktiken**
Här ligger patchhantering och sårbarhetshantering, right-sizing både för last och
för kostnad, versionsuppgraderingar, arkitekturändringar som att gå från virtuella
maskiner till containrar eller lägga till en kö eller en cache. I större miljöer
tillkommer compliance och revision, exempelvis PCI eller HIPAA, samt kostnadsstyrning
och uppföljning per team.

**09:08 Automatisering av livscykeln**
Eftersom allt är kod kan varje del av livscykeln automatiseras. Byte av image från
version ett till version två blir en kodändring som Terraform rullar ut över hela
miljön. Samma sak med att skala upp eller ner en databas.

**10:13 Policy as code**
Policyer skrivs som kod och kan träffa kostnad, säkerhet, compliance och
driftsäkerhet.

**10:49 Var policyn körs**
Policyn körs mellan `plan` och `apply`, alltså efter att Terraform räknat ut vad
som ska hända men innan något ändras i molnmiljön. Exempel som ges är en ny
brandväggsregel som öppnar mot hela internet, en databas där kryptering stängs av,
och en nedskalning till en enda maskin bakom load balancern som skapar en single
point of failure.

**11:43 Moduler**
Applikationer liknar varandra. Många är Java-applikationer, många använder samma
typ av databas. I stället för att beskriva samma mönster om och om igen samlas det
i en modul.

**12:20 Inputs och outputs**
En modul tar emot inputs, exempelvis antal instanser, vilken jar-fil och vilka
regioner, och lämnar outputs, exempelvis DNS-adressen till load balancern.
Komplexiteten kapslas in i modulen och den som använder den behöver bara känna till
in- och utgångarna.

**13:00 Registry**
Moduler publiceras i en registry och blir återanvändbara byggblock. Ett mönster för
Java, ett för C#, ett för databaser. Team komponerar större miljöer av dem i stället
för att uppfinna hjulet varje gång.

**13:40 Modulens egen livscykel**
Moduler versioneras. Vid en sårbarhet eller ny runtime publiceras en ny version, den
gamla fasas ut och berörda team notifieras. På så sätt går hundratals applikationer
att uppgradera på ett konsekvent sätt.

**14:32 Community edition och Terraform Cloud**
Day zero och day one klaras ofta med community edition. Vid enterprise-utmaningarna i
day two och framåt tillkommer modulregistry delad mellan team, policyer i plan- och
apply-cykeln, rollbaserad åtkomstkontroll och integrationer.

**15:13 Integrationer**
Patchning och konfigurationshantering kopplas till verktyg som Ansible.
Kostnadsuppföljning och right-sizing kopplas till FinOps-verktyg som Apptio,
Turbonomic och Cloudability. Säkerhet kopplas till verktyg som Wiz.

**16:04 Sentinel och OPA**
Policy as code körs antingen med Open Policy Agent eller med HashiCorps egen motor
Sentinel. Båda stöds.

**16:20 Revision och spårbarhet**
Central hantering ger svar på vem som ändrade vad och när, vilka workspaces som
finns, vilken plan som kördes och vad som skilde mellan två state-filer.

**17:06 Packer och images**
Samma filosofi appliceras på maskinimages. Packer bygger images som kod, både
VM-images som AMI, Azure- och GCP-images och containerimages som Docker. Images
versioneras, uppdateras vid ny Linux-version eller ny runtime, publiceras till
många team och tas bort när de är uttjänta.

**18:33 Waypoint och developer portals**
Utvecklare vill sällan bry sig om infrastrukturens detaljer. Waypoint fungerar som
ett översättningslager mellan vad som är utvecklarens ansvar och vad som är
plattformsteamets. Utvecklaren säger att den vill ha en Java-app med en databas,
och Waypoint kopplar det till Terraform-moduler. Resultatet kallas golden patterns.

**20:07 Actions**
Varje mönster kopplas till åtgärder, exempelvis build, deploy och rollback. Build
kan köra CI/CD-pipelinen, deploy kan använda Helm mot Kubernetes och rollback har
sin egen sekvens. Plattformsteamet definierar arbetsflödena i kod och utvecklarna
konsumerar dem som självbetjäning.

**21:07 Provider-ekosystemet**
Terraform når molnen Amazon, Google, Azure och Oracle, on-prem som VMware och
OpenStack, hårdvara som Cisco nätverksutrustning och lagringsappliances, samt
plattformar som Kubernetes och SaaS-tjänster som Datadog och PagerDuty.

### Vad videon inte tar upp

Ingen HCL-syntax, ingen terminal, inga kommandon utöver `plan` och `apply` som
begrepp. Inget om `init`, `fmt`, `validate` eller `import`. Inget om variables,
outputs, locals eller data sources. Inget om `count` eller `for_each`. Inget om
remote state, backend eller state locking. Inget om Terraform mot Kubernetes i
praktiken.

---

## 2026-08-17  Course intro

**Underlag**
Kursintro på plats.

### Genomgånget innehåll

Upplägget för kursen. Flipped Classroom, alltså eget material som presenteras för
läraren, med kort grundgenomgång och hands-on från föreläsaren. Ingen handledning
i kursen. Schemat vecka 34 till 45 med grupprojekt från vecka 39 och final labb
vecka 44. Instuderingsreferenser skickas till Martin före varje föreläsning i
formatet `[författare (person/org); innehållstitel; länk]`.

---

## Mall

```
## ÅÅÅÅ-MM-DD  Ämne

**Underlag**
`[författare (person/org); innehållstitel; länk]`

### Genomgånget innehåll

**Avsnitt**
Vad avsnittet gick igenom, i egna ord.

### Vad materialet inte tar upp
```

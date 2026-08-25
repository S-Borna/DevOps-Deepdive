# Logg

Nyaste överst. En post per genomgånget material.

---

## 2026-08-24  CMT, Ansible

**Underlag**
Inspelad föreläsning, Chas Academy. Fil: 03-CMT+ANSIBLE.mp4, 108:43. Flipped
classroom-lektion (diskussion utifrån studenternas egen inläsning, ingen
utdelad kurslitteratur), med en praktisk Ansible-demo körd av läraren Giacomo
Turatto mot en Hetzner-VM. Första lektionen efter sommaruppehåll, inspelningen
kraschade två gånger i början av passet innan den stabiliserades.

### Genomgånget innehåll

**Kursupplägg, flipped classroom**
Sista kursen innan LIA. Tanken är att lämna över ansvaret för inläsning helt
på studenterna, som förberedelse för hur LIA fungerar, ingen kommer stå bredvid
och peka ut material under LIA heller. Inga färdiga länkar delas ut, bara ämne
i kalendern ("CMT Ansible"). Kursmålen finns i Canvas. AI är tillåtet under
kursens gång men inte under provet.

**CMT — Configuration Management Tools**
CMT är mjukvarulösningar som automatiserar deployment, installation och
konfigurering av IT-infrastruktur, uttryckt i deklarativa YAML-filer. Exempel
på verktyg: Ansible, Terraform, SaltStack, Puppet, Chef. Ansible i synnerhet
bygger på en `inventory` (lista över noder, QDN eller IP, i YAML- eller
INI-format — båda ger samma resultat, valet är smak) och en eller flera
`playbooks` som beskriver vad som ska hända på de noderna.

**Deklarativt vs. imperativt**
Deklarativa verktyg (Terraform) beskriver önskat slutresultat, och verktyget
räknar själv ut vilka steg (deltan) som krävs för att nå dit. Imperativa
verktyg (Ansible) kör de steg man skrivit, i den ordningen man skrivit dem.
Konsekvensen demonstrerades senare i praktiken: tar man bort en task ur en
Ansible-playbook försvinner inte det tasken en gång installerade, playbooken
har ingen egen modell av "önskat sluttillstånd" att räkna tillbaka mot.

**Varför Ansible är branschstandard**
Länge etablerat, stor community, open source utan licenskostnad (till skillnad
från Terraform, som bytt licens — det har gett upphov till en öppen källkods-fork
kallad OpenTofu). Stort bibliotek av inbyggda och community-moduler. Framför
allt agentlöst: Ansible kräver bara SSH-åtkomst till målmaskinen, ingen extra
mjukvara behöver installeras eller hållas igång på noderna, vilket sänker
tröskeln rejält jämfört med verktyg som kräver en egen agentprocess på varje
server.

**Ansible-demo: inventory och ad-hoc-kommandon**
Läraren skapade en Ubuntu 26.04-VM manuellt i Hetzners konsol (det studenterna
sedan ska göra via Terraform i stället) och byggde en tom mapp med en
inventory-fil. Första försöket med `ansible <inventory> -m ping --pattern all`
gav `unreachable`, felsökt gemensamt i klassen: SSH-nyckeln och användaren
måste anges explicit i inventoryn (variablerna som nämndes vid namn:
`ansible_user`, `ansible_ssh_private_key_file`, samt `ansible_host` för att
kunna ge en IP-adress ett läsbart alias i stället för att använda IP:n som
nyckel rakt av). Ansibles ping-modul är inte ett ICMP-ping utan en SSH-baserad
nåbarhetskontroll. (Exakt YAML syns inte i det här underlaget — bara den
muntliga genomgången och vad som beskrevs i chatten, ingen skärmbild av koden
själv fanns tillgänglig här.)

**Playbooks**
En playbook är en YAML-fil med en eller flera `play`, separerade med
tre bindestreck (`---`, samma YAML-dokumentseparator som i övriga kursmaterial).
Varje play har `hosts` (targets) och `tasks` (lista av åtgärder). Varje task
namnges och pekar på en modul med fullt namn, t.ex. `ansible.builtin.ping`
eller `ansible.builtin.apt`, inte bara kortnamnet, eftersom flera moduler kan
heta samma sak i olika namnrymder. Kört med `ansible-playbook <inventory>
<playbook>.yml`. Första tasken i varje körning är alltid `Gathering Facts`,
som samlar info om målmaskinen (RAM, CPU, disk, distro) utan att man behöver
be om det, och som andra tasks senare kan använda.

**apt-modulen och "changed" vs "ok"**
Demo av `ansible.builtin.apt` för att uppgradera paket (`state: latest`,
`name: '*'`) och installera ett enskilt paket (`curl`, testat med `state:
present`). Ett vanligt nybörjarfel demonstrerades live: parametern hette
`update_cache`, inte `update_state` som gissningen var, och Ansible svarade
med felmeddelande och en lista över giltiga parametrar. Output skiljer på
`ok` (task lyckades, ingen ändring behövdes) och `changed` (task lyckades och
ändrade något). Kör man om samma playbook mot en redan konfigurerad maskin
ska allt bli `ok` utan `changed` — det användes som ett sanity check-mönster:
bygg playbooken stegvis, och kör den till sist mot en helt ny miljö
(`terraform destroy` + `terraform apply`, sedan hela playbooken från början)
för att verifiera att inget manuellt SSH-fixande smugit sig in under vägen.

**Ansible är imperativt, i praktiken**
Togs bort en task som installerade `curl` ur playbooken och kördes om, `curl`
fanns kvar på maskinen — playbooken hade bara aldrig sagt åt den att
avinstallera. Enda sättet att ta bort något är en egen task med `state:
absent`, köra den tills den blir `changed`, och därefter (om man vill) ta bort
tasken igen. Samma resonemang gäller brandväggsportar eller vad som helst
annat en task en gång ändrat.

**become (sudo)**
`become: true` höjer rättigheter med sudo för de tasks som behöver det (t.ex.
apt-uppgraderingar, som annars gav "permission denied" på apt:s låsfil).
Kan sättas på hela play-nivån eller per task; läraren visade att per-task är
att föredra så att tasks som inte behöver root (som ping) inte körs som root
i onödan.

**Skapa användare, och varför man inte ska SSH:a in som root**
`ansible.builtin.user` demonstrerades för att skapa en användare (`name`
krävs, saknas den failar tasken direkt med tydligt felmeddelande;
`create_home` är default true men skrevs ut explicit för läsbarhetens skull).
Rekommendationen: jobba aldrig löpande som root över SSH. Första Ansible-tasken
mot en ny maskin bör vara att skapa en dedikerad användare (sudo-rättigheter,
egen SSH-nyckel) och stänga root-inloggning, samma mönster som stängdes av
manuellt i tidigare kurser via `PermitRootLogin`.

**Known_hosts och man-in-the-middle-varningen**
När VM:en byggdes om fick den nytt SSH-nyckelpar, och klienten vägrade koppla
upp sig ("host key changed"-varningen), förklarat som ett skydd mot att någon
kapar routingen och låtsas vara målservern. Löst antingen genom att radera den
gamla raden ur `~/.ssh/known_hosts`, eller genom att sätta
`ANSIBLE_HOST_KEY_CHECKING=false` som miljövariabel för sessionen (att
föredra i CI framför att stänga av kontrollen permanent i konfigurationen).

**Terraform + Ansible tillsammans**
Vanligt arbetsflöde: Terraform spinner upp infrastrukturen, Ansible
konfigurerar den efteråt. Terraform kan köra enkla konfigurationsskript
(cloud-init/cloud-config, som också är YAML) men ersätter inte Ansible för
egentlig konfigurationshantering. En students fråga om `AppArmor`-relaterade
"permission denied"-fel vid Terraform+libvirt/KVM lämnades öppen (inte löst i
sessionen).

**Praktiskt: Hetzner-åtkomst och gruppindelning**
Studenterna får inte logga in i Hetzner-konsolen, all interaktion sker via
Terraform (samt `hcloud`-CLI för att lista resurser). Grupperna (slumpade)
delas in efter ett gemensamt Hetzner-projekt/token per grupp. Enligt Slack-
tråden (Giacomo Turatto, delad separat från lektionen) gäller för varje grupp:
max en VM per person, minsta tillgängliga VM-typ i första hand i ordningen
CX23 → CAX11 → CPX12 (byt VM-typ eller availability zone om `terraform apply`
inte hittar tillgänglighet), `terraform destroy` innan man rundar av för
dagen, och ett gemensamt SSH-nyckelpar för gruppen som delas både internt och
med läraren. Said är i grupp 2 tillsammans med Simon, Resa, Fatima, William
och Christian.

**Examination**
Inget skriftligt prov, i stället ett praktiskt prov med dator, utan AI.
Gruppprov med en individuell del, detaljerna kommer senare. Komplettering
bokas till våren, inte direkt efter kursen (för kort startsträcka annars),
men det är viktigt att boka tid omgående om provet inte klaras — annars
riskerar kompletteringskön att bli fulltecknad av ettornas kompletteringar.

**Gruppprojekt**
Målet är uttalat: sätta upp och drifta ett Kubernetes-kluster på ett
automatiserat sätt. Fler krav kommer senare. Fem grupper om fem-sex personer
vardera, plus en student (Vincent) som kör solo med individuella
specialleverabler för att komplettera kursmål från tidigare.

**LIA-status**
Sex studenter saknade LIA-plats vid lektionstillfället (Emil, Elinor,
Christian, Lisa, Victor, Simon). Rådet var att fortsätta söka aktivt, LIA
börjar i november oavsett när den hittas, och man kan extra-jobba hos en
framtida LIA-arbetsgivare innan dess utan att det räknas in i LIA-perioden.

### Vad videon inte tar upp

Ingen genomgång av roller (`roles`), `handlers`, `vault` för hemligheter,
loopar eller villkorssatser i Ansible (nämnda i förbifarten som existerande
men inte visade). Ingen CI-integration av Ansible ännu, det är ämnet för
nästa lektion (onsdag, "CMT i CI-pipeline"). Ingen Windows-specifik Ansible
(läraren flaggade själv att den saknar egen erfarenhet där). AppArmor/KVM-
permission-frågan från en student lämnades olöst. Ingen exakt kod syns
återgiven här eftersom underlaget för den här posten var en muntlig
sammanfattning och transkription, inte en bildanalys av skärmen.

---

## 2026-08-19  IaC och Terraform, föreläsning (Chas Academy)

**Underlag**
Inspelad föreläsning, Chas Academy. Fil: `02-IaC+Terraform.mkv`, 28:56.
Flipped classroom, vecka 34 onsdag. Skärmdelning med slides och live-demo i
terminal och webbläsare.

### Genomgånget innehåll

**00:00 Öppning**
Läraren frågar vilka som inte var med i måndags och stämmer av var alla står.
Förklarar att kursen kör flipped classroom, alltså att teorin ska läsas själv
innan föreläsningen, och att föreläsningarna därför blir korta. Nämner att
inspelningen av materialet inte hann laddas upp i tid, och hänvisar till
grovschemat för att se vilka ämnen som kommer vilken vecka.

**01:13 Öppen fråga om IaC och Terraform**
En kursdeltagare (Alexander) sammanfattar vad hen läst på egen hand: Terraform
låter en programmatiskt tilldela infrastrukturresurser i stället för att skapa
varje VM för hand, det är ett deklarativt språk där man beskriver hur man vill
att det ska se ut och Terraform räknar ut hur. Nämner kommandon för att
initiera, validera syntax och se en plan, samt att Terraform har en
autocomplete som kan installeras, jämförbart med `kubectl`.

**02:07 Fråga om labbmiljö**
En kursdeltagare frågar om gruppen får en egen Hetzner-server att labba mot
eller om de är låsta till egna maskiner till gruppprojektet. Läraren är osäker
på exakt upplägg och hänvisar till att kolla med Giacomo.

**04:25 OpenTofu**
Nämns kort som en open source-variant av Terraform, skapad när Terraform
slutade vara open source för tre år sedan. Målet med OpenTofu beskrivs som att
en Terraform-uppsättning ska gå att flytta över med minimala ändringar.

**05:20 Övergång till dagens teori**
Läraren går över till grunderna i Terraform, baserat på HashiCorps
Terraform Docker-tutorial.

**05:39 Vad Terraform-filer innehåller**
`.tf`-filer läses in av Terraform oavsett filnamn. En Terraform-fil kan
innehålla config, providers, variabler, resurser och outputs.

**06:15 Genomgång av `main.tf` rad för rad (slide)**
Kodrutan på slidesen visar hela filen:

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.2.0"
    }
  }
}

provider "docker" {}

variable "nginx_image" {
  type = string
}

resource "docker_image" "nginx" {
  name         = var.nginx_image
  keep_locally = false
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "tutorial"
  ports {
    internal = 80
    external = 8000
  }
}

output "nginx_ports" {
  value = docker_container.nginx.ports
}
```

Rad 1-8 är `terraform`-blocket med `required_providers`. Rad 10 definierar
providern `docker`. Rad 12-14 definierar variabeln `nginx_image` som en
sträng. Rad 16-19 är resursen `docker_image.nginx`, som refererar variabeln
via `var.nginx_image`. En kursdeltagare frågar hur Terraform vet att den ska
hämta imagen från Docker Hub — svaret är att det är providern som avgör det,
och att man annars får kolla providerns dokumentation. Rad 21-28 är
`docker_container.nginx`, som refererar imagen via
`docker_image.nginx.image_id`. En annan fråga (Alexander) handlar om att dela
upp Terraform-kod i flera filer kontra en enda `main.tf`. Läraren svarar att
hen gjort båda, och att uppdelning per kontext (till exempel en egen fil för
DNS-konfiguration) är en bra metod, men att allt i en fil duger vid tidsbrist.
Rad 30-32 är output-blocket `nginx_ports`, som skrivs ut i terminalen efter
att ett kommando körts.

**12:18 De tre sätten att sätta variabelvärden**
Miljövariabel i CLI: `export TF_VAR_nginx_image=nginx:latest`. Flagga vid
kommandokörning: `terraform apply -var 'nginx_image=nginx:latest'`, där man
kan upprepa `-var` för flera variabler. Fil: en fil som heter
`terraform.tfvars` läses in automatiskt som standard. En fil med annat namn
kan läsas in med en command-flagga men måste ändå ha filändelsen `.tfvars`.
Filer som slutar på `.auto.tfvars` läses också in automatiskt, utan flagga.

**14:53 Vanliga Terraform CLI-kommandon**
`terraform init` startar ett projekt och hämtar dependencies/providers.
`terraform validate` läser igenom filerna i mappen och kollar syntax och
variabler. `terraform plan` ger en teoretisk output av hur resultatet blir,
så man kan se att allt stämmer innan något körs. `terraform apply` lägger
till resultatet hos providern. `terraform destroy` tar bort allt som är
definierat i Terraform-filerna.

**16:17 Övergång till live-demo**
Läraren delar skärm och kör en mer konkret demonstration i terminal och
webbläsare, med en tom mapp och samma exempel som i slidesen.

**17:00 Filen på disk**
```console
$ ls
$ cp .done/main.tf main.tf
$ cat main.tf
```
`cat` skriver ut `main.tf` med exakt samma innehåll som slidesen (se
kodblocket ovan). Läraren lägger sedan till en `terraform.tfvars`-fil för att
variabeln ska läsas in automatiskt.

**18:50 Första `terraform init`-försöket misslyckas**
```console
$ terraform init
Error: Missing newline after argument

  on terraform.tfvars line 1:
   1: nginx_image = nginx:latest

An argument definition must end with a newline.
```
Felet upprepas en gång till efter en första redigering med `vim` — värdet
`nginx:latest` i `terraform.tfvars` saknade citattecken/rätt radslut. Efter
en andra redigering går `terraform init` igenom:

```console
$ vim terraform.tfvars
$ terraform init
Initializing the backend...
Initializing provider plugins...
- Finding kreuzwerker/docker versions matching "~> 4.2.0"...
- Installing kreuzwerker/docker v4.2.0...
- Installed kreuzwerker/docker v4.2.0 (self-signed, key ID 0DCEG98927DAF8EC)
Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://developer.hashicorp.com/terraform/cli/plugins/signing

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
$ ls
main.tf  terraform.tfvars
$ ls -a
.  ..  .done  main.tf  .terraform  .terraform.lock.hcl  terraform.tfvars
$ terraform validate
Success! The configuration is valid.
```
Läraren nämner att `.terraform` och `.terraform.lock.hcl` normalt aldrig
behöver röras för hand, men att lock-filen ska in i versionshanteringen, och
att den finns för att förhindra att flera körningar krockar samtidigt.

**20:33 `terraform apply`**
```console
$ terraform apply

  # docker_container.nginx will be created
  + resource "docker_container" "nginx" {
      ...
      ports {
          + external = 8000
          + internal = 80
          + ip       = "0.0.0.0"
          + protocol = "tcp"
        }
    }

  # docker_image.nginx will be created
  + resource "docker_image" "nginx" {
      + id          = (known after apply)
      + image_id    = (known after apply)
      + keep_locally = false
      + name        = "nginx:latest"
      + repo_digest = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + nginx_ports = [
      + {
          + external = 8000
          + internal = 80
          + ip       = "0.0.0.0"
          + protocol = "tcp"
        },
    ]

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

docker_image.nginx: Creating...
docker_image.nginx: Still creating... [00m10s elapsed]
docker_image.nginx: Creation complete after 14s [id=sha256:5253dc86cc93ac6249902934655c6f7c959d8caa45a8c2ecc0b95953834d8ee8nginx:latest]
docker_container.nginx: Creating...
docker_container.nginx: Creation complete after 1s [id=145bef842a16d55c83a01fad511cfba6ec6d518f8da0924050cc9e4feb8e787d]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

nginx_ports = tolist([
  {
    "external" = 8000
    "internal" = 80
    "ip" = "0.0.0.0"
    "protocol" = "tcp"
  },
])
```
Läraren påpekar att de flesta attributen stod som `(known after apply)` i
planen eftersom Terraform ännu inte gjort några beräkningar, bara kontrollerat
att filen fungerar.

**21:23 Verifiering i webbläsaren**
`http://127.0.0.1:8000` visar Dockers standardsida "Welcome to nginx! If you
see this page, nginx is successfully installed and working." — port 8000 på
värdmaskinen mappad mot port 80 i containern, precis som i `ports`-blocket.

**22:00 `terraform destroy`, två felstavade försök**
```console
$ terraform destroy -auto-aprove
Error: Failed to parse command-line flags

flag provided but not defined: -auto-aprove

For more help on using this command, run:
  terraform destroy -help
$ terraform destroy -auto-aprove=yes
Error: Failed to parse command-line flags

flag provided but not defined: -auto-aprove

For more help on using this command, run:
  terraform destroy -help
$ terraform destroy -auto-approve
docker_image.nginx: Refreshing state... [id=sha256:5253dc86cc93ac6249902934655c6f7c959d8caa45a8c2ecc0b95953834d8ee8nginx:latest]
docker_container.nginx: Refreshing state... [id=145bef842a16d55c83a01fad511cfba6ec6d518f8da0924050cc9e4feb8e787d]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # docker_container.nginx will be destroyed
  - resource "docker_container" "nginx" {
      ...
    }
```
Flaggan saknade ett `p` (`-auto-aprove` i stället för `-auto-approve`) i de
två första försöken. Terraform går igenom hela filen, hittar resurserna och
tar bort dem. Läraren visar efteråt att webbsidan på port 8000 inte längre
svarar, eftersom containern är borta.

**22:45 Kursdeltagarnas hands on-uppgift**
Installera Terraform och följa HashiCorps Terraform Docker-tutorial, som är
samma exempel som visats i demot. Giacomo kommer ge tillgång till andra
providers, eftersom gruppprojektet jobbar mot en Hetzner-servermiljö i
stället för lokal Docker.

**23:32 Inför nästa vecka**
Instudera Configuration Management Tools (CMT) och Ansible, bekräftat av en
slide med rubriken "Instudering — Configuration Management Tools (CMT) —
Ansible".

**23:45–28:56 Frågor och avslutning**
Ingen ny teknisk genomgång. Diskussion om flipped classroom-upplägget
framöver (föreläsningarna blir korta eftersom teorin läses på egen hand,
hands on kan ta olika lång tid beroende på hur mycket som behöver felsökas),
tips om att jobba i studiegrupper, praktisk info om schemat (distans på
måndagar, på plats på onsdagar) och att kursen räknas som heltidsstudier,
ungefär 40 timmar i veckan inklusive föreläsningstid.

### Täcker från förra posten

Fyller några av luckorna som "Terraform Basics, arbetsflödet och state"
flaggade: `variable`-blocket visas och förklaras, liksom `terraform.tfvars`
och alla tre sätten att sätta variabelvärden (miljövariabel, `-var`-flagga,
tfvars-fil inklusive `.auto.tfvars`). `output`-blocket visas också, om än
kort.

### Vad videon inte tar upp

Ingen `terraform fmt` eller `terraform import`. Inget om `count`, `for_each`
eller `data source`. Ingen `depends_on`. Ingen praktisk genomgång av moduler,
workspaces eller remote state/backend — bara det som redan var teoretiskt
genomgånget i tidigare instuderingsmaterial. Policy as code, Sentinel och OPA
nämns inte alls i den här föreläsningen. OpenTofu nämns bara i förbigående,
utan praktisk jämförelse. Ingen annan provider än `docker` konfigureras eller
visas, trots att gruppprojektet kommer använda Hetzner.

---

## 2026-08-19  Egen körning, första Terraform-resursen

**Underlag**
Egen körning, `terraform/forsta-forsok/`. Terraform installerad via Homebrew,
`hashicorp/tap`. `terraform version` ger `Terraform v1.15.8` på `darwin_arm64`.

### Gjort

Byggde en första resurs och körde hela arbetsflödet, `init`, `plan`, `apply`,
`plan` igen och sist nedrivningen. Providern är `hashicorp/local`, alltså skapas
en fil på disk i stället för något i molnet.

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

resource "local_file" "hej" {
  content  = "Hej, detta är min första Terraform-resurs."
  filename = "${path.module}/hello.txt"
}
```

`init` löste versionsvillkoret `~> 2.4` till en konkret version och skrev
låsfilen.

```console
$ terraform init
Initializing provider plugins...
- Finding hashicorp/local versions matching "~> 2.4"...
- Installing hashicorp/local v2.9.0...
- Installed hashicorp/local v2.9.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above.
```

`plan` visade resursen som ska skapas. De sju `content_*`-attributen sätts av
providern och inte av konfigurationen, alltså står de som `(known after apply)`.

```console
$ terraform plan

  # local_file.hej will be created
  + resource "local_file" "hej" {
      + content              = "Hej, detta är min första Terraform-resurs."
      + content_base64sha256 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha256       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0777"
      + filename             = "./hello.txt"
      + id                   = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

```console
$ terraform apply
local_file.hej: Creating...
local_file.hej: Creation complete after 0s [id=ff2da409f7e0801a82028a80658f52158ba84612]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

### Problem

Försökte läsa `hej.txt` och fick ingen fil.

```console
$ cat hej.txt
cat: hej.txt: No such file or directory
```

Felet var att jag läste resursnamnet som filnamn. `"hej"` i
`resource "local_file" "hej"` är etiketten Terraform använder internt, alltså det
som blir adressen `local_file.hej` i state och i planen. Filnamnet på disk styrs
av attributet `filename`.

### Löst genom

Läste planutskriften igen och såg raden `filename = "./hello.txt"`. Filen låg där
hela tiden.

```console
$ cat hello.txt
Hej, detta är min första Terraform-resurs.
```

Ett `plan` direkt efter `apply` bekräftade att konfigurationen och verkligheten
stämde överens.

```console
$ terraform plan
No changes. Your infrastructure matches the configuration.
```

Nedrivningen tog bort filen och tömde state.

```console
$ terraform destroy
Plan: 0 to add, 0 to change, 1 to destroy.
local_file.hej: Destroying... [id=ff2da409f7e0801a82028a80658f52158ba84612]
local_file.hej: Destruction complete after 0s

Apply complete! Resources: 0 added, 0 changed, 1 destroyed.
```

State gick från `serial 1` med en resurs till `serial 3` med en tom resurslista.
Backupfilen `terraform.tfstate.backup` innehåller läget före nedrivningen, med
`filename` satt till `./hello.txt` och samma id som `apply` skrev ut.

### Vad jag tar med mig

Resursnamnet och det som resursen faktiskt skapar är två skilda saker. Namnet är
Terraforms adress för resursen, exempelvis vid `terraform state show
local_file.hej`. Vad som hamnar på disk eller i molnet står i attributen.
Planutskriften är därför facit och inte konfigurationen ur minnet.

### Kvar

Testa en riktig molnresurs, exempelvis med AWS-providern, i stället för
`local_file`. Se hur state ser ut när flera resurser hänger ihop genom
referenser, alltså det som `Terraform Basics` visade med image och container.

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

## Mallar

Två sorters poster. Genomgånget material och egen körning.

### Mall, genomgånget material

```
## ÅÅÅÅ-MM-DD  Ämne

**Underlag**
`[författare (person/org); innehållstitel; länk]`

### Genomgånget innehåll

**Avsnitt**
Vad avsnittet gick igenom, i egna ord.

### Vad materialet inte tar upp
```

### Mall, egen körning

```
## ÅÅÅÅ-MM-DD  Ämne

**Underlag**
Egen körning, sökväg i repot. Version på verktyget.

### Gjort
Vad som byggdes och kördes. Koden som kodblock, output som console-block.

### Problem
Vad som gick fel.

### Löst genom
Vad som löste det, med output som bevis.

### Vad jag tar med mig
Lärdomen, inte händelsen.

### Kvar
Vad som är otestat och vad nästa steg är.
```

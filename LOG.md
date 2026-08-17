# Logg

Nyaste överst. En post per genomgånget material.

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

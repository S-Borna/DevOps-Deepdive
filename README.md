# DevOps Deepdive

DevOps Deepdive, Chas Academy. Sista kursen före LIA.

## Kursinnehåll

| Ämne | Vad det är |
|---|---|
| IaC, Terraform | Beskriv infrastrukturen som kod och applicera den |
| CMT, Ansible | Configuration management, konfigurera det som redan står upp |
| IaC & CMT i CI-pipeline | Kör Terraform och Ansible automatiskt i pipelinen |
| Helm | Paketera Kubernetes-manifest till installerbara charts |
| ArgoCD | GitOps, klustret hämtar sitt önskade läge från git |
| cert-manager, external-dns | Automatiska TLS-certifikat och DNS-poster i klustret |
| k8s secrets management | Hantera hemligheter utan att de hamnar i git |
| Monitoring, alarms | Mät klustret och larma när något går fel |
| Logging | Samla och sök loggar från alla poddar |
| Zero Trust, Least Privilege | Ingen får mer åtkomst än uppgiften kräver |

Schema och instuderingsformat ligger i [`docs/schema.md`](docs/schema.md).

## Upplägg

| Del | Så funkar det |
|---|---|
| Format | Flipped Classroom, du hittar eget material och presenterar ämnet |
| Föreläsning | Kort grundgenomgång plus hands-on, resten är frågor från studenterna |
| Instudering | Länkar skickas till Martin före varje föreläsning |
| Handledning | Finns inte i kursen |
| Grupprojekt | Vecka 39 till 43 |
| Final labb | Vecka 44, individuell |
| Komplettering | Vecka 45, tisdag |

## Examination

| Moment | Kursmål |
|---|---|
| Teamprojekt med muntlig presentation | 9-10, 12-13 |
| Individuella laborationer | 8, 11 |

Betyg IG, G eller VG. VG kräver kursmål 12, analysera och optimera
utvecklingsprocesser i yrkesrollen som DevOps Engineer. En ordinarie examination
plus en (1) omexamination per moment.

## Kursmål

Kunskaper

1. Zero Trust och Least Privilege
2. Principer och funktioner inom CI/CD
3. DevOps-arbetssätts syfte och mål i projekt och organisationer
4. Uppsättning och design av en DevOps-miljö och process för ett modernt systemutvecklingsprojekt
5. DevOps-lösningar i containerorkestrering såsom Docker Swarm och Kubernetes

Färdigheter

6. Planera standardiseringen av byggen i systemutvecklingsprojekt
7. Genomföra uppsättning av CD/CI-pipelines för olika miljöer från test till produktion
8. Använda och konfigurera programvaror i syfte att övervaka och hantera spårbarhet
9. Utföra automatisering och orkestrering av den kontinuerliga leveransen
10. Utföra grundläggande drift av containerbaserade applikationer i orkestreringsmiljöer
11. Skapa och hantera health check/probes för applikationer och infrastruktur

Kompetenser

12. Analysera och optimera utvecklingsprocesser i yrkesrollen som DevOps Engineer
13. Säkerställa genomförandet av CI/CD-flöden med hjälp av skriptning med Bash och Python

## Struktur

| Mapp | Innehåll |
|---|---|
| `docs/` | Schema, kursplan, anteckningar |
| `notes/` | Egna anteckningar per ämne |
| `labs/` | Labbar och kod |

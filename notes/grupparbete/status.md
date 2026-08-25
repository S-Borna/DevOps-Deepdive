# Grupp 2 — status

Grupp 2: Said, Simon, Resa, Fatima, William, Christian. Nycklar och token ligger utanför repot, lokalt hos var och en.

## 2026-08-25

Hetzner-onboarding klar. Gemensamt SSH-nyckelpar (grupp2, port 2222, ingen passphrase) delat med Giacomo. Token mottaget från Giacomo och verifierat mot Hetzner API. William testade SSH mot en manuellt uppsatt VM (Ubuntu 24.04, samma nyckel/user/port som vi enats om) och det fungerade, VM:en är nedriven igen efter testet så det är 0 servrar uppe i projektet just nu. Jag har verifierat nyckel och token lokalt men har ingen egen VM uppe än, och inget Terraform/Ansible-arbete mot Hetzner i repot ännu.

## Kvar att göra

Skriva Terraform-kod för grupp 2:s VM, max en per person, VM-typ CX23 → CAX11 → CPX12 i den ordningen. Bygga en Ansible-playbook för uppgradering, användarhantering och att stänga root-login, Giacomo vill att vi testar den mot en egen VM (VirtualBox/Pi/etc.) innan vi kör mot Hetzner. Enas om var Terraform-koden ska bo, delat repo för gruppen eller var och en i sitt eget.

## Beslut

Gemensamt SSH-användarnamn grupp2, port 2222.

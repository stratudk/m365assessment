# M365 Reality Check – vejledning til **Mac**

Her er trin for trin, hvordan du kører vores sikkerhedstjek af jeres Microsoft
365-miljø og sender resultatet tilbage til os. Du behøver ikke kunne noget teknisk –
følg bare de 7 trin i rækkefølge.

> **Det er helt sikkert at køre.** Tjekket er **kun læsende** – det aflæser jeres
> sikkerhedsindstillinger og ændrer **ingenting** i jeres miljø. Der oprettes ingen
> app-registrering, og der installeres intet permanent. Resultatfilen indeholder kun
> testresultater – **ingen adgangskoder eller hemmeligheder.**

**Tid:** ca. 10–20 minutter. Det meste er ventetid, hvor du bare lader vinduet stå.

**Du skal bruge:**

- En **administrator-konto** til Microsoft 365 (find den i trin 1).
- En Mac, hvor du må installere programmer (ellers hjælper jeres it-support i trin 2).

---

## Trin 1: Find den rigtige konto

Tjekket **skal** køres med en **administrator-konto**. Med en almindelig
brugerkonto bliver næsten alle testene sprunget over, og resultatet kan ikke bruges.

> Her betyder "administrator" en konto i **Microsoft 365** – det er ikke det samme
> som at være administrator på selve din Mac.

Sådan finder du ud af, hvilken konto det er:

1. Åbn **https://admin.microsoft.com** i din browser.
2. **Kommer du ind på siden?** Så er det den konto, du skal bruge i trin 5.
3. **Får du "adgang nægtet"?** Så har du sandsynligvis en ekstra konto til
   administration – den hedder typisk noget med "admin", fx `admin.navn@firma.dk`.
   Prøv at logge ind med den i stedet.
4. **Har du ikke sådan en konto?** Kontakt din Statu-konsulent, før du går videre.

Notér brugernavnet på administrator-kontoen – du skal bruge det i trin 5.

> **Log ud igen, når du har fundet den.** Klik på dine initialer øverst til højre →
> **Log ud**. Så undgår du, at login i trin 5 automatisk vælger den forkerte konto.

---

## Trin 2: Installér PowerShell 7

1. Åbn programmet **Terminal** (tryk ⌘+mellemrum, skriv `Terminal`, tryk Enter).
2. Har du ikke **Homebrew** i forvejen, så installér det først ved at følge
   vejledningen på **https://brew.sh**
3. Kopiér denne kommando ind i Terminal, og tryk Enter:
   ```
   brew install powershell
   ```
4. Bliver du bedt om din **Mac-adgangskode**, så skriv den (der vises ingen tegn,
   mens du skriver – det er normalt) og tryk Enter.

> Skriv **ikke** `sudo` foran kommandoen – Homebrew skal køres som dig selv.

---

## Trin 3: Hent scriptet

1. Åbn **https://github.com/stratudk/m365assessment** i din browser.
2. Klik på filen **`Run-Maester.ps1`** i listen.
3. Klik på download-knappen oppe til højre over filen (**"Download raw file"** –
   ikonet med pilen nedad).
4. Filen lander i mappen **Overførsler** (Downloads).

---

## Trin 4: Start tjekket

1. Åbn **Terminal**.
2. Skriv dette – **med et mellemrum til sidst**:
   ```
   pwsh -File 
   ```
3. **Træk filen `Run-Maester.ps1` fra Overførsler ind i vinduet** med musen. Så
   indsættes stien automatisk.
4. Tryk **Enter**.

Linjen kommer til at se nogenlunde sådan ud:

```
pwsh -File ~/Downloads/Run-Maester.ps1
```

**Vær tålmodig:** Først installeres værktøjerne, og der kan gå **et par minutter,
før login-vinduet dukker op**. Det er normalt – luk ikke vinduet imens.

> **Brug ikke `sudo`.** Tjekket installerer kun ting til din egen brugerprofil, og
> med `sudo` kan resultatfilen ende et andet sted, end vejledningen siger.

---

## Trin 5: Log ind med administrator-kontoen

Efter et par minutter åbner der et **browservindue** med en login-side.

1. **Se efter, hvilken konto der står på siden.**
   - Er det administrator-kontoen fra trin 1? Så fortsæt.
   - Er det en anden konto? Klik på **"Brug en anden konto"** ("Use another
     account"), og log ind med administrator-kontoen.
2. Godkend den **læsende** adgang, der bliver spurgt om.
3. Det gentager sig **4–5 gange** – én gang for hver tjeneste (Entra, Exchange,
   Teams, Purview og Azure). Det er helt normalt. **Brug den samme
   administrator-konto hver gang.**

| Hvis du ser dette | Så gør du sådan |
| --- | --- |
| Du bliver logget ind uden at blive spurgt – med den forkerte konto | Luk fanen, log ud på https://www.office.com (initialer øverst til højre → **Log ud**), og gentag trin 4. |
| Login-siden beder om godkendelse igen og igen | Det er de forskellige tjenester. Godkend hver enkelt med samme konto. |

---

## Trin 6: Vent på resultatet

Nu kører testene i nogle minutter. Du skal ikke gøre noget – lad bare vinduet stå.

- At nogle tests bliver **"Skipped" (sprunget over)** er helt normalt. Det betyder
  bare, at funktionen eller licensen ikke findes hos jer.
- Bliver **næsten alle** sprunget over, er du logget ind med den forkerte konto.
  Gentag trin 4 og 5 med administrator-kontoen.

Til sidst kommer der en **grøn besked** med stien til resultatfilen.

---

## Trin 7: Send resultatet til os

Filen hedder **`maester-results.json`** og ligger som standard i din hjemmemappe:

```
/Users/ditnavn/maester-results.json
```

Tip: I **Finder** kan du trykke ⌘+⇧+H for at åbne hjemmemappen, hvor filen ligger.

Vedhæft filen i en mail til din Statu-konsulent.

Det var det – tak! Vi klarer resten.

---

## Hvis noget går galt

| Problem | Løsning |
| --- | --- |
| "pwsh: command not found" | PowerShell 7 er ikke installeret. Gentag trin 2. |
| "Administrator rights are required to install or update" | Du kører en ældre udgave af scriptet. Hent den nyeste (trin 3), og kør igen. Du skal **ikke** køre som administrator. |
| "Sign-in did not complete" | Login blev ikke gennemført. Gentag trin 4, og gennemfør alle login-trin. |
| Adgang nægtet, eller næsten alle tests sprunget over | Forkert konto. Log ud i browseren, gentag trin 4, og vælg **"Brug en anden konto"**. |
| Der åbnes slet ikke noget browservindue | Kør kommandoen fra trin 4 igen med `-UseDeviceCode` til sidst. Så får du en kort kode, du indtaster på https://microsoft.com/devicelogin. |
| Noget helt andet | Tag et skærmbillede af fejlbeskeden, og send det til os – så hjælper vi. |

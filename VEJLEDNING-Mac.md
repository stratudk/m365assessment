# M365 Reality Check – vejledning til **Mac**

Denne vejledning hjælper dig med at køre vores sikkerhedstjek på jeres Microsoft 365-miljø
og sende resultatet tilbage til os.

> **Det er helt sikkert at køre.** Tjekket er **kun læsende** – det aflæser jeres
> sikkerhedsindstillinger og ændrer **ingenting** i jeres miljø. Der oprettes ingen
> app-registrering, og der installeres intet permanent. Resultatfilen indeholder kun
> testresultater – **ingen adgangskoder eller hemmeligheder.**

Du skal regne med ca. **10–20 minutter** i alt. Det meste er ventetid, mens tjekket kører.

---

## 1. Før du går i gang

Du skal bruge **PowerShell 7**.

1. Åbn programmet **Terminal** (findes under Programmer → Hjælpeprogrammer, eller
   søg efter "Terminal" med Spotlight ⌘+mellemrum).
2. Hvis du ikke allerede har **Homebrew**, så installér det først ved at følge
   vejledningen på https://brew.sh
3. Installér PowerShell 7:
   ```
   brew install powershell
   ```

**Rettigheder:** Log ind med en konto, der har rollen **Global Reader** eller
**Security Reader**. En almindelig brugerkonto virker også, men så bliver nogle af
testene sprunget over – det er helt normalt.

> **Har du en separat administrator-konto?** Mange har én konto til daglig brug og
> en anden til administration. Brug i så fald **din administrator-konto**, når du
> logger ind i trin 5 – det er den, der har rettighederne til at aflæse alle
> indstillinger og dermed giver det mest komplette resultat.

---

## 2. Hent scriptet

Scriptet ligger på GitHub her:
**https://github.com/stratudk/m365assessment**

1. Åbn linket i en browser.
2. Klik på filen **`Run-Maester.ps1`** i fillisten.
3. Klik på download-knappen (**"Download raw file"** – ned-pil-ikonet) oppe til
   højre over filen.
4. Filen gemmes i din mappe **Overførsler** (Downloads).

---

## 3. Start PowerShell 7

I **Terminal** skriver du `pwsh` og trykker Enter.
Du har nu en kommandolinje klar (linjen begynder typisk med `PS`).

---

## 4. Kør tjekket

Skriv `pwsh -File ` (med mellemrum til sidst), **træk derefter filen `Run-Maester.ps1`
ind i vinduet** med musen (så indsættes stien automatisk), og tryk Enter.

Kommandoen kommer til at se nogenlunde sådan ud:
```
pwsh -File ~/Downloads/Run-Maester.ps1
```

Tjekket går nu i gang. **Vær tålmodig:** Først installeres de nødvendige værktøjer, og
der kan gå **et par minutter, før login-vinduet dukker op**. Det er normalt – luk ikke
vinduet imens.

---

## 5. Log ind

Når du bliver bedt om det:

1. Der åbnes et **browservindue**. Log ind med din arbejdskonto – har du en
   **separat administrator-konto**, så brug den.
2. Godkend den **læsende** adgang, der bliver spurgt om.
3. Du bliver sandsynligvis bedt om at logge ind **flere gange** i træk
   (Entra/Graph, Exchange Online, Teams, Purview og Azure). Det er forventet –
   godkend hver enkelt.

> Hvis der ikke kan åbnes et browservindue, så kør i stedet:
> `pwsh -File <sti til filen> -UseDeviceCode` – så får du i stedet en kort kode,
> som du indtaster på https://microsoft.com/devicelogin i en anden fane.

---

## 6. Vent på resultatet

Selve testene kører i nogle minutter. Du behøver ikke gøre noget imens.

At nogle tests bliver **"Skipped" (sprunget over)** er helt normalt – det betyder
bare, at den funktion eller licens ikke findes i jeres miljø.

Når alt er færdigt, viser vinduet en grøn besked med **stien til resultatfilen**.

---

## 7. Send resultatet til os

Til sidst i vinduet står der præcis, hvor filen ligger. Som standard:

- `/Users/ditnavn/maester-results.json`

**Sådan sender du den:**
1. Find filen **`maester-results.json`** på det viste sted. (Tip: i **Finder** kan du
   trykke ⌘+⇧+H for at åbne din hjemmemappe, hvor filen ligger.)
2. Vedhæft den i en mail til din Statu-konsulent.

Det var det – tak! Vi tager os af resten.

---

## Hvis noget går galt

- **"pwsh: command not found":** PowerShell 7 er ikke installeret. Gentag trin 1.
- **"Sign-in did not complete":** Login blev ikke gennemført. Kør kommandoen i trin 4
  igen og gennemfør alle login-trin.
- **Browseren åbner ikke:** Brug `-UseDeviceCode` som beskrevet i trin 5.
- **Andet:** Tag et skærmbillede af fejlbeskeden og send det til os, så hjælper vi.

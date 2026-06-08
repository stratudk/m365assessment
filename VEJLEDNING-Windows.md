# StratuOne sikkerhedstjek – vejledning til **Windows**

Denne vejledning hjælper dig med at køre vores sikkerhedstjek på jeres Microsoft 365-miljø
og sende resultatet tilbage til os.

> **Det er helt sikkert at køre.** Tjekket er **kun læsende** – det aflæser jeres
> sikkerhedsindstillinger og ændrer **ingenting** i jeres miljø. Der oprettes ingen
> app-registrering, og der installeres intet permanent. Resultatfilen indeholder kun
> testresultater – **ingen adgangskoder eller hemmeligheder.**

Du skal regne med ca. **15–25 minutter** i alt. Det meste er ventetid, mens tjekket kører.

---

## 1. Før du går i gang

Du skal bruge **PowerShell 7** (ikke den gamle "Windows PowerShell 5.1", der følger med Windows).

1. Åbn menuen **Start**, skriv `Terminal` eller `PowerShell`, og åbn den.
2. Indsæt denne kommando og tryk Enter for at installere PowerShell 7:
   ```
   winget install Microsoft.PowerShell
   ```
3. Luk vinduet og åbn et **nyt** vindue, så den nye version er aktiv.

**Rettigheder:** Log ind med en konto, der har rollen **Global Reader** eller
**Security Reader**. En almindelig brugerkonto virker også, men så bliver nogle af
testene sprunget over – det er helt normalt.

> **Har du en separat administrator-konto?** Mange har én konto til daglig brug og
> en anden til administration. Brug i så fald **din administrator-konto**, når du
> logger ind i trin 5 – det er den, der har rettighederne til at aflæse alle
> indstillinger og dermed giver det mest komplette resultat.

---

## 2. Hent scriptet

Gem filen **`Run-Maester.ps1`**, som du har fået fra os, et sted du kan finde igen –
fx i mappen **Overførsler** (Downloads).

---

## 3. Start PowerShell 7

Åbn **PowerShell 7** (skriv `pwsh` i Start-menuen og tryk Enter).
Du har nu en kommandolinje klar.

---

## 4. Kør tjekket

Skriv `pwsh -File ` (med mellemrum til sidst), **træk derefter filen `Run-Maester.ps1`
ind i vinduet** med musen (så indsættes stien automatisk), og tryk Enter.

Kommandoen kommer til at se nogenlunde sådan ud:
```
pwsh -File C:\Users\ditnavn\Downloads\Run-Maester.ps1
```

Tjekket går nu i gang. Først installeres de nødvendige værktøjer (det tager et par
minutter første gang).

---

## 5. Log ind

Når du bliver bedt om det:

1. Der åbnes et **browservindue**. Log ind med din arbejdskonto – har du en
   **separat administrator-konto**, så brug den.
2. Godkend den **læsende** adgang, der bliver spurgt om.
3. Du bliver sandsynligvis bedt om at logge ind **flere gange** i træk
   (Entra/Graph, Exchange Online, Teams, Purview og Azure). Det er forventet –
   godkend hver enkelt.

> Hvis der ikke kan åbnes et browservindue (fx på en server), så kør i stedet:
> `pwsh -File <sti til filen> -UseDeviceCode` – så får du i stedet en kort kode,
> som du indtaster på https://microsoft.com/devicelogin i en anden fane.

---

## 6. Vent på resultatet

Selve testene kører i nogle minutter. Du behøver ikke gøre noget imens.

- At nogle tests bliver **"Skipped" (sprunget over)** er helt normalt – det betyder
  bare, at den funktion eller licens ikke findes i jeres miljø.
- Til sidst kører der **automatisk et ekstra tjek** (CISA "ScubaGear"), som dækker
  bl.a. Power Platform og Teams. Det giver **endnu et par login-prompter** og tager
  lidt længere tid. Godkend også her den læsende adgang.

Når alt er færdigt, viser vinduet en grøn besked med **stien til resultaterne**.

---

## 7. Send resultatet til os

Til sidst i vinduet står der præcis, hvor filerne ligger. Som standard:

- Resultatfil: `C:\Users\ditnavn\maester-results.json`
- Ekstra rapport-mappe: `C:\Users\ditnavn\scuba-results`

**Sådan sender du dem:**
1. Find filen **`maester-results.json`** og vedhæft den i en mail til din
   StratuOne-konsulent.
2. Hvis der også er en mappe ved navn **`scuba-results`**: højreklik på mappen →
   **"Send til"** → **"Komprimeret mappe (zip)"**, og vedhæft zip-filen i samme mail.

Det var det – tak! Vi tager os af resten.

---

## Hvis noget går galt

- **"pwsh kendes ikke" / "command not found":** PowerShell 7 er ikke installeret,
  eller vinduet er ikke genstartet. Gentag trin 1 og åbn et nyt vindue.
- **"Sign-in did not complete":** Login blev ikke gennemført. Kør kommandoen i trin 4
  igen og gennemfør alle login-trin.
- **Browseren åbner ikke:** Brug `-UseDeviceCode` som beskrevet i trin 5.
- **Andet:** Tag et skærmbillede af fejlbeskeden og send det til os, så hjælper vi.

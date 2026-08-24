# M365 Reality Check

Dette repository indeholder et lille værktøj fra **Statu**, der laver et
**sikkerhedstjek** af jeres Microsoft 365-miljø og samler resultatet i en fil, du
sender tilbage til din Statu-konsulent.

> 🔒 **Det er helt sikkert at køre.** Tjekket er **kun læsende** – det aflæser jeres
> sikkerhedsindstillinger og ændrer **ingenting** i jeres miljø. Der oprettes ingen
> app-registrering, og der installeres intet permanent. Resultatfilen indeholder kun
> testresultater – **ingen adgangskoder eller hemmeligheder.**

## Sådan kommer du i gang

Følg vejledningen for dit styresystem:

- 🪟 **Windows:** [VEJLEDNING-Windows.md](VEJLEDNING-Windows.md)
- 🍎 **Mac:** [VEJLEDNING-Mac.md](VEJLEDNING-Mac.md)

Vælg den rigtige – trinene (installation, filstier og afslutning) er forskellige på de
to styresystemer.

## Hvad sker der, kort fortalt

1. Der installeres nogle PowerShell-værktøjer, kun for din session.
2. Du logger ind med en **administrator-konto** og godkender **læsende** adgang.
3. Værktøjet [Maester](https://maester.dev) kører en række sikkerhedstests mod jeres
   miljø (Entra, Exchange, Teams, Purview m.fl.).
4. Resultatet gemmes som en fil, du sender tilbage til os.

Det tager typisk **10–25 minutter**, hvoraf det meste er ventetid.

## Krav

- **PowerShell 7** (installeres som en del af vejledningen).
- En **administrator-konto** til Microsoft 365 – altså den konto, der kan logge ind på
  https://admin.microsoft.com. Har I en separat admin-konto, er det den, der skal
  bruges. Med en almindelig brugerkonto bliver næsten alle tests sprunget over, og
  resultatet kan ikke bruges.

## Spørgsmål?

Er du i tvivl om noget, så kontakt din Statu-konsulent – vi hjælper gerne.

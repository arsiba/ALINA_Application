<script>
  import Layout from '../layouts/layout.svelte';
</script>

<svelte:head>
  <title>Cookie-Hinweise | ALINA</title>
  <meta name="description" content="Informationen zu den Sicherheits-Cookies und dem Teilnahme-Cookie zum Schutz der ALINA-Befragung vor Mehrfachteilnahmen." />
</svelte:head>

<Layout>
  <div lang="de" class="mx-auto max-w-3xl px-6 py-10 sm:py-14">
    <p class="text-sm font-medium text-muted-foreground">ALINA · Cookies</p>
    <h1 class="mt-3 text-3xl font-semibold tracking-tight sm:text-4xl">Was dein Browser speichert</h1>
    <p class="mt-5 leading-relaxed text-muted-foreground">ALINA setzt Cookies für die sichere Formularübermittlung und für den Schutz der Befragung vor Mehrfachteilnahmen ein. Es gibt keine Werbe- oder Analyse-Cookies. Der Teilnahme-Cookie enthält keine Befragungskennung, Antworten, LLM-Inhalte oder persönlichen Scores.</p>

    <section aria-labelledby="security-heading" class="mt-8 border-t pt-6">
      <h2 id="security-heading" class="text-xl font-semibold">Sitzungs-Cookie für die sichere Übermittlung</h2>
      <p class="mt-3 text-sm leading-relaxed text-muted-foreground">Das Rails-Sitzungs-Cookie schützt unter anderem die Formularübermittlung vor gefälschten Anfragen (CSRF). Es enthält verschlüsselte technische Sitzungsinformationen und ist ein Sitzungscookie ohne festes Ablaufdatum. Je nach Browser-Einstellung kann eine Sitzung beim Wiederherstellen von Fenstern fortbestehen. Es enthält keine Forschungsantworten oder Scores und wird nicht zur Zuordnung der Befragungsdatensätze verwendet.</p>
    </section>

    <section aria-labelledby="participation-cookie-heading" class="mt-8 border-t pt-6">
      <h2 id="participation-cookie-heading" class="text-xl font-semibold">Teilnahme-Cookie zum Schutz vor Mehrfachteilnahmen</h2>
      <dl class="mt-4 grid gap-x-6 gap-y-3 text-sm sm:grid-cols-[auto_1fr]">
        <dt class="font-medium">Name und Wert</dt><dd class="text-muted-foreground"><code>alina_participated=1</code></dd>
        <dt class="font-medium">Zweck</dt><dd class="text-muted-foreground">Weitere Teilnahmen in demselben Browser nach einem erfolgreichen Abschluss verhindern, um die Befragung vor wiederholten Einsendungen zu schützen.</dd>
        <dt class="font-medium">Zeitpunkt</dt><dd class="text-muted-foreground">Erst nach erfolgreicher letzter Übermittlung. Ein Besuch, ein Abbruch oder eine fehlgeschlagene Übermittlung setzt den Cookie nicht.</dd>
        <dt class="font-medium">Speicherdauer</dt><dd class="text-muted-foreground">30 Tage ab dem Setzen. Seitenaufrufe und Wiederholungen derselben bestätigten Übermittlung verlängern die Laufzeit nicht.</dd>
        <dt class="font-medium">Inhalt</dt><dd class="text-muted-foreground">Nur das Abschlusskennzeichen „1“. Kein Zeitstempel, keine eindeutige Nutzerkennung und keine Verknüpfung mit einem bestimmten Forschungsdatensatz.</dd>
        <dt class="font-medium">Zugriff</dt><dd class="text-muted-foreground">Erstanbieter-Cookie für diese Website, ohne Freigabe für andere Domains. HttpOnly verhindert das direkte Auslesen durch JavaScript. Bei HTTPS wird Secure gesetzt; SameSite=Lax begrenzt die Übermittlung bei seitenübergreifenden Anfragen.</dd>
      </dl>
      <p class="mt-4 text-sm leading-relaxed text-muted-foreground">Die Sperre bezieht sich auf einen Browser, nicht auf eine identifizierte Person. Cookies können gelöscht werden und andere Browser erkennen wir damit nicht wieder. Umgekehrt können mehrere Personen denselben Browser verwenden. Deshalb kann diese Maßnahme nicht jede Mehrfachteilnahme ausschließen und ist kein Nachweis der Identität einer Person. Dein persönlicher Score kann mit diesem Cookie nicht wiederhergestellt werden.</p>
    </section>

    <section aria-labelledby="cookie-control-heading" class="mt-8 border-t pt-6">
      <h2 id="cookie-control-heading" class="text-xl font-semibold">Hinweis und Browser-Einstellungen</h2>
      <p class="mt-3 text-sm leading-relaxed text-muted-foreground">„Verstanden“ schließt nur den Cookie-Hinweis für den aktuellen Seitenbesuch. Es wird dafür weder ein zusätzlicher Cookie noch ein Eintrag im lokalen Browserspeicher angelegt. Über „Cookie-Hinweis anzeigen“ im Fußbereich kannst du ihn erneut öffnen. Das Schließen ist keine Einwilligung.</p>
      <p class="mt-3 text-sm leading-relaxed text-muted-foreground">Cookies kannst du in deinem Browser sperren oder löschen. Dann funktioniert die browserbezogene Wiederholungssperre nicht mehr zuverlässig. Bereits gespeicherte Forschungsantworten werden durch das Löschen nicht entfernt, da sie nicht über den Teilnahme-Cookie zugeordnet sind. Bitte nimm unabhängig vom verwendeten Browser pro Person nur einmal teil.</p>
    </section>

    <section aria-labelledby="cookie-law-heading" class="mt-8 border-t pt-6">
      <h2 id="cookie-law-heading" class="text-xl font-semibold">Rechtsgrundlage und Zweckbindung</h2>
      <p class="mt-3 text-sm leading-relaxed text-muted-foreground">Nach § 25 Abs. 1 TDDDG erfordert das Speichern oder Auslesen von Informationen auf einem Endgerät grundsätzlich eine Einwilligung. § 25 Abs. 2 Nr. 2 nimmt unbedingt erforderliche Vorgänge aus, die einen ausdrücklich gewünschten digitalen Dienst ermöglichen. Die Datenschutzkonferenz berücksichtigt dabei auch nutzerorientierte Betrugsprävention; eine pauschale Bezeichnung als Sicherheits-Cookie genügt nicht.</p>
      <p class="mt-3 text-sm leading-relaxed text-muted-foreground">ALINA ordnet den Teilnahme-Cookie dieser Ausnahme zu: Die angeforderte Befragung sieht eine einmalige Teilnahme vor. Der Cookie wird ausschließlich zur Durchsetzung der browserbezogenen Wiederholungssperre gesetzt und ausgelesen, erst nach Abschluss und mit auf 30 Tage begrenzter Laufzeit. Er dient weder Werbung noch Reichweitenmessung oder dem Abruf persönlicher Ergebnisse.</p>
      <p class="mt-3 text-sm leading-relaxed text-muted-foreground">Die Einordnung betrifft diese konkrete Funktion und ist keine allgemeine Ausnahme für Forschungs-Cookies. Die Rechtsgrundlage für die Verarbeitung der Forschungsantworten und weiterer personenbezogener Betriebsdaten ist hiervon getrennt zu betrachten. Diese Cookie-Hinweise ersetzen keine vollständigen Datenschutzhinweise zum Studienbetrieb.</p>
      <ul class="mt-4 space-y-3 text-sm underline underline-offset-4">
        <li><a href="https://www.gesetze-im-internet.de/ttdsg/__25.html" rel="noreferrer">§ 25 TDDDG – Schutz der Privatsphäre bei Endeinrichtungen</a></li>
        <li><a href="https://datenschutzkonferenz-online.de/media/oh/20221130_OH_Telemedien_Version_1.1.pdf" rel="noreferrer">Datenschutzkonferenz: Orientierungshilfe, Abschnitt III.3.b – Erforderlichkeit und Betrugsprävention</a></li>
      </ul>
</section>
  </div>
</Layout>

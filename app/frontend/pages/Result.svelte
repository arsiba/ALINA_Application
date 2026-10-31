<script>
  import { Link } from '@inertiajs/svelte';
  import Layout from '../layouts/layout.svelte';
  import { formPath } from '../routes';
  import { buttonVariants } from '$lib/components/ui/button/index.js';
  import MetricSummary from '$lib/components/results/MetricSummary.svelte';
  import CategoryResults from '$lib/components/results/CategoryResults.svelte';
  import GroupResults from '$lib/components/results/GroupResults.svelte';
  import { number, percent } from '$lib/components/results/format.js';

  let { results } = $props();
  let overall = $derived(results.overall);
  const sections = [
    ['overview', 'Gesamtbild'], ['categories', 'Attribute'], ['groups', 'Gruppen'], ['method', 'Berechnung & Grenzen'],
  ];
  const rate = (count) => overall.evaluable_count ? count / overall.evaluable_count : null;
</script>

<svelte:head>
  <title>Auswertung | ALINA</title>
  <meta name="description" content="Ergebnisse der ALINA-Befragung: Erwartungen an KI-Chatbots, bestätigte Angaben und die Awareness-Gap. Mit Erklärung der Berechnung und ihrer Grenzen." />
  <meta name="robots" content="noindex" />
</svelte:head>

<Layout>
  <div lang="de" class="mx-auto max-w-5xl px-6 pb-16 [overflow-wrap:anywhere]">
    <header class="py-8 sm:py-10">
      <p class="text-sm font-medium text-muted-foreground">ALINA · Auswertung</p>
      <h1 class="mt-4 max-w-3xl text-4xl font-semibold leading-tight tracking-tight sm:text-5xl">Was wir erwarten.<br />Was der Chatbot ableitet.</h1>
      <p class="mt-5 max-w-3xl text-base leading-relaxed text-muted-foreground">Die Awareness-Gap zeigt, wo Erwartungen an persönliche Angaben eines KI-Chatbots und die anschließende Bewertung seiner Antworten auseinandergehen. Hier siehst du die Ergebnisse der abgeschlossenen Befragungen.</p>
      <a href="#method" class="mt-3 inline-flex min-h-11 items-center text-sm font-medium underline underline-offset-4">So wird die Awareness-Gap berechnet</a>
    </header>

    {#if !results.available}
      <section aria-labelledby="locked-heading" class="rounded-xl border bg-muted/40 p-6 sm:p-9">
        <p class="text-xs font-medium uppercase tracking-widest text-muted-foreground">Veröffentlichung ausstehend</p>
        <h2 id="locked-heading" class="mt-3 text-2xl font-semibold tracking-tight">Ergebnisse ab {number(results.minimum_participants)} abgeschlossenen Teilnahmen</h2>
        <p class="mt-4 max-w-2xl leading-relaxed text-muted-foreground">Für diese Fragebogenversion ist die Mindestteilnehmerzahl noch nicht erreicht. Bis dahin werden keine Kennzahlen veröffentlicht. Auch später gelten für Gruppenvergleiche Mindestgrößen.</p>
        <p class="mt-3 text-sm leading-relaxed text-muted-foreground">Falls du gerade teilgenommen hast: Deine Antworten sind gespeichert. Die öffentliche Auswertung wird freigegeben, sobald die Grenze erreicht ist.</p>
        <Link href={formPath()} class={buttonVariants({ class: 'mt-6 min-h-11' })}>Zur Befragung</Link>
      </section>
    {:else}
      <div class="flex flex-wrap items-center justify-between gap-3 border-y py-4 text-sm">
        <p><strong class="font-semibold tabular-nums">{number(results.participant_count)}</strong> abgeschlossene Teilnahmen <span class="px-1 text-muted-foreground">·</span> Fragebogenversion {results.instrument_version}</p>
        <p class="text-muted-foreground">Deskriptive Ergebnisse dieser Stichprobe</p>
      </div>
      <nav aria-label="Bereiche der Auswertung" class="flex flex-wrap gap-x-6 gap-y-1 py-4 text-sm text-muted-foreground">
        {#each sections as [id, label]}<a href={`#${id}`} class="inline-flex min-h-11 items-center underline-offset-4 hover:text-foreground hover:underline">{label}</a>{/each}
      </nav>

      <section id="overview" aria-labelledby="overview-heading" class="scroll-mt-6 py-6 sm:py-8">
        <div class="mb-7 flex flex-wrap items-baseline justify-between gap-3">
          <h2 id="overview-heading" class="text-2xl font-semibold tracking-tight">Das Gesamtbild</h2>
          <p class="text-sm text-muted-foreground">Alle auswertbaren Antworten gemeinsam</p>
        </div>
        <MetricSummary summary={overall} />
        <div class="mt-8 grid gap-6 border-t pt-6 sm:grid-cols-3">
          <div><h3 class="text-sm font-medium">Erwartung stimmt überein</h3><p class="mt-2 text-2xl font-semibold tabular-nums">{percent(overall.agreement_rate)}</p><p class="mt-2 text-sm leading-relaxed text-muted-foreground">{number(overall.agreement_count)} Antworten: eine korrekte Angabe erwartet und bestätigt, oder keine korrekte Angabe erwartet und auch keine bestätigt.</p></div>
          <div><h3 class="text-sm font-medium">Mittelwert je Person</h3><p class="mt-2 text-2xl font-semibold tabular-nums">{percent(overall.mean_individual_gap_rate)}</p><p class="mt-2 text-sm leading-relaxed text-muted-foreground">Durchschnitt der individuellen Awareness-Gaps. Jede der {number(overall.participants_with_evaluable_answers)} Personen mit auswertbaren Antworten zählt gleich viel.</p></div>
          <div><h3 class="text-sm font-medium">Auswertbare Antworten</h3><p class="mt-2 text-2xl font-semibold tabular-nums">{percent(overall.coverage_rate)}</p><p class="mt-2 text-sm leading-relaxed text-muted-foreground">{number(overall.evaluable_count)} von {number(overall.response_count)} Antworten. Bei {number(overall.participants_without_evaluable_answers)} Personen ist keine Kategorie auswertbar.</p></div>
        </div>
      </section>

      <section id="categories" aria-labelledby="category-heading" class="scroll-mt-6 border-t py-8 sm:py-10">
        <p class="text-xs font-medium uppercase tracking-widest text-muted-foreground">Acht Attributkategorien</p>
        <h2 id="category-heading" class="mt-2 text-2xl font-semibold tracking-tight">Wo Erwartungen und Angaben auseinandergehen</h2>
        <p class="mt-3 max-w-2xl text-sm leading-relaxed text-muted-foreground">Wechsle zwischen den Abweichungen und dem Vergleich erwarteter mit bestätigten korrekten Angaben. Die Farben zeigen dieselben Anteile wie im Gesamtbild.</p>
        <CategoryResults categories={results.categories} />
      </section>

      <section aria-labelledby="quality-heading" class="border-t py-8 sm:py-10">
        <h2 id="quality-heading" class="text-2xl font-semibold tracking-tight">Welche Antworten fließen ein?</h2>
        <p class="mt-3 max-w-2xl text-sm leading-relaxed text-muted-foreground">Eine fehlende Ableitung ist ein Ergebnis. Eine verweigerte oder nicht prüfbare Angabe wird dagegen aus der Berechnung ausgeschlossen. Diese Fälle werden deshalb getrennt ausgewiesen.</p>
        <dl class="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {#each [
            ['Als richtig bestätigt', overall.correct_count, 'Auswertbar'],
            ['Als falsch bewertet', overall.incorrect_count, 'Auswertbar'],
            ['Keine Ableitung (null)', overall.not_inferred_count, 'Auswertbar; keine bestätigte korrekte Angabe'],
            ['Ausgeschlossen', overall.excluded_count, 'Verweigert oder nicht prüfbar'],
          ] as [label, count, note]}
            <div class="rounded-lg border p-5"><dt class="text-sm font-medium text-muted-foreground">{label}</dt><dd class="mt-2 text-3xl font-semibold tabular-nums">{number(count)}</dd><dd class="mt-2 text-xs leading-relaxed text-muted-foreground">{note}</dd></div>
          {/each}
        </dl>
        <p class="mt-4 text-sm text-muted-foreground">Ausschlüsse: {number(overall.refused_count)} Sicherheitsverweigerungen und {number(overall.invalid_count)} vorhandene, aber nicht prüfbare Angaben. Insgesamt {number(overall.excluded_count)} von {number(overall.response_count)} Antworten.</p>

        <h3 class="mt-8 text-base font-semibold">Erwartung trifft Bewertung</h3>
        <p class="mt-2 text-sm leading-relaxed text-muted-foreground">Die vier Kombinationen innerhalb der {number(overall.evaluable_count)} auswertbaren Antworten. „Nicht bestätigt“ umfasst falsche Angaben und Nicht-Ableitungen.</p>
        <div class="mt-4 overflow-x-auto rounded-lg border" role="region" aria-label="Erwartung und Bewertung: horizontal scrollbare Kreuztabelle">
          <table class="w-full min-w-[32rem] text-left text-sm tabular-nums">
            <caption class="sr-only">Kreuztabelle der Erwartungen und bestätigten korrekten Angaben. Prozentwerte beziehen sich auf alle auswertbaren Antworten.</caption>
            <thead class="bg-muted/60 text-muted-foreground"><tr><th scope="col" class="px-5 py-4 font-medium">Korrekte Angabe erwartet?</th><th scope="col" class="px-5 py-4 font-medium">Als richtig bestätigt</th><th scope="col" class="px-5 py-4 font-medium">Nicht bestätigt</th></tr></thead>
            <tbody class="divide-y">
              <tr><th scope="row" class="px-5 py-4 font-medium">Ja</th><td class="px-5 py-4">{number(overall.expected_correct_count)} · {percent(rate(overall.expected_correct_count))}<span class="mt-1 block text-xs text-muted-foreground">Übereinstimmung</span></td><td class="px-5 py-4">{number(overall.overestimation_count)} · {percent(overall.overestimation_rate)}<span class="mt-1 block text-xs text-muted-foreground">Überschätzung</span></td></tr>
              <tr><th scope="row" class="px-5 py-4 font-medium">Nein</th><td class="px-5 py-4">{number(overall.underestimation_count)} · {percent(overall.underestimation_rate)}<span class="mt-1 block text-xs text-muted-foreground">Unterschätzung</span></td><td class="px-5 py-4">{number(overall.expected_failure_count)} · {percent(rate(overall.expected_failure_count))}<span class="mt-1 block text-xs text-muted-foreground">Übereinstimmung</span></td></tr>
            </tbody>
          </table>
        </div>
      </section>

      <section id="groups" aria-labelledby="groups-heading" class="scroll-mt-6 border-t py-8 sm:py-10">
        <h2 id="groups-heading" class="text-2xl font-semibold tracking-tight">Unterschiede innerhalb der Stichprobe</h2>
        <p class="mt-3 max-w-2xl text-sm leading-relaxed text-muted-foreground">Die Basisdaten erlauben aggregierte Vergleiche nach verwendeter LLM-Anwendung und ausreichend großen Altersgruppen. Die Raten bündeln alle auswertbaren Antworten einer Gruppe. Es werden keine Kombinationen beider Merkmale veröffentlicht.</p>
        <h3 class="mt-7 text-base font-semibold">Nach LLM-Anwendung</h3>
        <GroupResults breakdown={results.models} minimum={results.minimum_participants} label="Nach LLM-Anwendung" />
        {#if results.age_groups.available}
          <section aria-labelledby="age-groups-heading" class="mt-8">
            <h3 id="age-groups-heading" class="text-base font-semibold">Nach Altersgruppe</h3>
            <p class="mt-2 text-sm leading-relaxed text-muted-foreground">Gezeigt werden nur Altersgruppen mit mindestens {number(results.minimum_participants)} abgeschlossenen Teilnahmen. Kleine Gruppen und gegebenenfalls zusätzliche Gruppen zum Schutz vor Rückrechnung bleiben ausgeblendet.</p>
            <GroupResults breakdown={results.age_groups} minimum={results.minimum_participants} label="Nach Altersgruppe" />
          </section>
        {/if}
        <p class="mt-4 text-xs leading-relaxed text-muted-foreground">Dies ist kein Leistungstest der Anbieter. Unterschiedliche Nutzungsweisen, verfügbare Chats, Memories und Modellversionen können die Ergebnisse beeinflussen. Die Gruppen sind nicht experimentell kontrolliert.</p>
      </section>
    {/if}

    <section id="method" aria-labelledby="method-heading" class="mt-10 scroll-mt-6 border-t pt-8 sm:pt-10">
      <p class="text-xs font-medium uppercase tracking-widest text-muted-foreground">Die Auswertung verstehen</p>
      <h2 id="method-heading" class="mt-2 text-2xl font-semibold tracking-tight">So wird gerechnet</h2>
      <div class="mt-6 grid gap-8 text-sm leading-relaxed sm:grid-cols-2 sm:gap-x-12">
        <div><h3 class="font-semibold">1. Erwartung vor der Auskunft</h3><p class="mt-2 text-muted-foreground">Für jede der acht Kategorien wird zuerst erfasst, ob eine korrekte Angabe erwartet wird. Erst anschließend wird die Antwort des Chatbots importiert und bewertet. Die ursprüngliche Erwartung bleibt unverändert.</p></div>
        <div><h3 class="font-semibold">2. Auswertbare Kategorien bestimmen</h3><p class="mt-2 text-muted-foreground">Richtige und falsche Angaben sowie eine Nicht-Ableitung (<code>null</code>) sind auswertbar. Sicherheitsverweigerungen und vorhandene, aber nicht prüfbare Angaben sind ausgeschlossen. Ohne auswertbare Kategorie ist eine Rate nicht berechenbar; sie wird nicht als 0 % dargestellt.</p></div>
        <div><h3 class="font-semibold">3. Abweichungen zählen</h3><p class="mt-2 text-muted-foreground">Eine unerwartet korrekte Angabe ist eine Unterschätzung. Eine erwartete korrekte Angabe, die falsch ausfällt oder nicht abgeleitet wurde, ist eine Überschätzung. Beide zusammen ergeben die Awareness-Gap.</p><p class="mt-3 rounded-md bg-muted/60 p-3 font-medium">Gap = (Unterschätzungen + Überschätzungen) / auswertbare Kategorien</p><p class="mt-2 text-muted-foreground">Beide Teilraten verwenden denselben Nenner. 0 % bedeutet vollständige Übereinstimmung, 100 % eine Abweichung in jeder auswertbaren Kategorie.</p></div>
        <div><h3 class="font-semibold">4. Ergebnisse zusammenführen</h3><p class="mt-2 text-muted-foreground">Im Gesamtbild und in den Vergleichen werden die Zähler und Nenner aller zugehörigen Antworten addiert. Personen mit mehr auswertbaren Kategorien tragen dadurch mehr bei. Der ergänzende „Mittelwert je Person“ gewichtet jede individuelle Gap gleich; Personen ohne auswertbare Kategorie gehen in diesen Mittelwert nicht ein.</p></div>
      </div>
      <details class="mt-7 rounded-lg border px-5">
        <summary class="min-h-12 cursor-pointer py-4 text-sm font-medium">Ein Rechenbeispiel und die Mengen aus dem Messmodell</summary>
        <div class="space-y-4 pb-5 text-sm leading-relaxed text-muted-foreground">
          <p>Von acht Kategorien sind sechs auswertbar. Bei einer wurde eine korrekte Angabe nicht erwartet, aber bestätigt. Bei zwei wurde sie erwartet, aber die Angabe war falsch oder das LLM lieferte <code>null</code>. Die anderen drei Erwartungen stimmen überein. Die Gap ist 3 / 6 = 50 %, die Unterschätzungsrate 1 / 6 ≈ 16,7 % und die Überschätzungsrate 2 / 6 ≈ 33,3 %. Die zwei ausgeschlossenen Kategorien verändern den Nenner nicht.</p>
          <p><strong class="text-foreground">V</strong> enthält die auswertbaren Kategorien einschließlich Nicht-Ableitungen. <strong class="text-foreground">Eᵥ</strong> enthält die Kategorien aus V mit erwarteter korrekter Angabe. <strong class="text-foreground">C</strong> enthält die Kategorien aus V mit bestätigter korrekter Angabe. Nicht-Ableitungen gehören nicht zu C. Die Gap ist die symmetrische Differenz: <span class="font-medium text-foreground">Gᵥ = (C ∖ Eᵥ) ∪ (Eᵥ ∖ C)</span>; ihre relative Größe ist <span class="font-medium text-foreground">gᵥ = |Gᵥ| / |V|</span>.</p>
        </div>
      </details>
      <div class="mt-8 border-l-2 pl-5">
        <h3 class="text-base font-semibold">Was diese Ergebnisse aussagen können</h3>
        <p class="mt-3 max-w-3xl text-sm leading-relaxed text-muted-foreground">Gemessen wird die Übereinstimmung von Erwartungen mit der durch die Teilnehmenden bewerteten Selbstauskunft eines LLM. Eine unabhängige Ground Truth wird nicht erhoben. Ob die Auskunft alle tatsächlich ableitbaren Informationen enthält und ob eine Angabe aus Chats, Memories oder anderen Hinweisen stammt, lässt sich damit nicht nachweisen.</p>
        <p class="mt-3 max-w-3xl text-sm leading-relaxed text-muted-foreground">Die Ergebnisse beschreiben die vorliegende Stichprobe und sind keine repräsentative Aussage über alle Nutzerinnen und Nutzer. Ausschlüsse können die Raten beeinflussen. Eine kleine Gap bedeutet eine gute Übereinstimmung innerhalb der auswertbaren Kategorien; sie ist kein Nachweis für geringe Datenschutzrisiken.</p>
        <p class="mt-3 max-w-3xl text-sm leading-relaxed text-muted-foreground">Veröffentlicht werden nur abgeschlossene Befragungen derselben Fragebogenversion, ab {number(results.minimum_participants)} Teilnahmen. Angefangene Befragungen fließen nicht ein. Konkrete LLM-Angaben, Chatverläufe und Memories werden von ALINA nicht zentral gespeichert. Einzelne Befragungen und persönliche Ergebnisse werden hier nicht angezeigt. Altersgruppen unterhalb der Mindestgröße und bei Bedarf weitere Gruppen bleiben ausgeblendet, damit sich kleine Restgruppen nicht aus der Gesamtsumme zurückrechnen lassen. Die Mindestgröße begrenzt die Veröffentlichung kleiner Gruppen, ist aber kein alleiniger Nachweis vollständiger Anonymität.</p>
      </div>
    </section>
    <footer class="mt-10 border-t pt-6 text-xs leading-relaxed text-muted-foreground">ALINA · Technische Messmethode im Rahmen einer Bachelorarbeit. Dargestellt wird die im Messmodell definierte Awareness-Gap einschließlich der getrennten Über- und Unterschätzung.</footer>
  </div>
</Layout>

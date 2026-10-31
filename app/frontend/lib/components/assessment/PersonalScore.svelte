<script>
  import { personalScore } from '$lib/assessment/personal-score.js';
  import { number, percent } from '$lib/components/results/format.js';

  let { submissions } = $props();
  let baseline = $derived(submissions.find(({ payload }) => payload.step === 'baseline')?.payload.data);
  let evaluation = $derived(submissions.find(({ payload }) => payload.step === 'evaluation')?.payload.data);
  let result = $derived(baseline && evaluation
    ? personalScore(baseline.expectations, evaluation.ratings, evaluation.inference_statuses)
    : null);
</script>

{#if result}
  <section aria-labelledby="personal-score-heading" class="mt-8 rounded-xl border p-5 sm:p-7">
    <p class="text-xs font-medium uppercase tracking-widest text-muted-foreground">Deine Erwartungen im Vergleich</p>
    <h2 id="personal-score-heading" class="mt-2 text-xl font-semibold tracking-tight">Dein persönlicher Awareness-Score</h2>

    <div role="note" aria-label="Nur jetzt verfügbar" class="mt-5 rounded-md border-l-4 border-orange-700 bg-orange-50 p-4 text-sm leading-relaxed dark:border-orange-400 dark:bg-orange-950/40">
      <p class="font-semibold">Nur jetzt verfügbar</p>
      <p class="mt-1">Dein persönlicher Score wird nur hier im Browser berechnet und nicht separat gespeichert. Nach dem Neuladen oder Verlassen dieser Seite kannst du ihn nicht erneut abrufen. Wenn du ihn behalten möchtest, notiere ihn oder mache einen Screenshot.</p>
      <p class="mt-2 text-xs text-muted-foreground">Die von dir bestätigten Forschungsantworten wurden wie angekündigt gespeichert. Diese persönliche Abschlussansicht wird nicht für einen späteren Abruf hinterlegt.</p>
    </div>

    <p class="mt-6 text-5xl font-semibold tracking-tight tabular-nums sm:text-6xl" data-testid="awareness-score">{percent(result.score)}</p>
    {#if result.score !== null}
      <p class="mt-3 text-sm leading-relaxed text-muted-foreground">Bei {number(result.agreement_count)} von {number(result.evaluable_count)} auswertbaren Kategorien stimmt deine Erwartung mit dem bewerteten Ergebnis überein.</p>
      <div class="mt-4 h-3 overflow-hidden rounded-full bg-muted" aria-hidden="true"><div class="h-full bg-teal-700 dark:bg-teal-400" style:width={`${result.score * 100}%`}></div></div>
    {:else}
      <p class="mt-3 text-sm leading-relaxed text-muted-foreground">Keine der acht Kategorien ist auswertbar. Deshalb sind dein Awareness-Score und deine Awareness-Gap nicht berechenbar; das entspricht nicht einem Score von 0 %.</p>
    {/if}

    <dl class="mt-6 grid gap-5 border-t pt-5 sm:grid-cols-3">
      {#each [['Awareness-Gap', result.gap_rate, result.gap_count], ['Unterschätzung', result.underestimation_rate, result.underestimation_count], ['Überschätzung', result.overestimation_rate, result.overestimation_count]] as [label, rate, count]}
        <div class="min-w-0"><dt class="text-sm text-muted-foreground">{label}</dt><dd class="mt-1 text-xl font-semibold tabular-nums">{percent(rate)}</dd><dd class="mt-1 text-xs text-muted-foreground">{number(count)} von {number(result.evaluable_count)} Kategorien</dd></div>
      {/each}
    </dl>
    <p class="mt-5 text-xs leading-relaxed text-muted-foreground">{number(result.evaluable_count)} von 8 Kategorien auswertbar · {number(result.excluded_count)} ausgeschlossen ({number(result.refused_count)} verweigert, {number(result.invalid_count)} nicht prüfbar) · {number(result.not_inferred_count)} ohne Ableitung (null)</p>
    <details class="mt-5 border-t pt-2 text-sm">
      <summary class="min-h-11 cursor-pointer py-3 font-medium">Was bedeutet mein Score?</summary>
      <div class="space-y-3 pb-1 leading-relaxed text-muted-foreground">
        <p>Awareness-Score = 100 % − Awareness-Gap. 100 % bedeutet, dass deine Erwartungen in jeder auswertbaren Kategorie mit dem Ergebnis übereinstimmen; 0 % bedeutet eine Abweichung in jeder auswertbaren Kategorie. Der Score ist eine Darstellung der Übereinstimmung im Messmodell und kein unabhängig validierter psychologischer Test.</p>
        <p>Eine unerwartet korrekte Angabe zählt als Unterschätzung. Eine erwartete korrekte Angabe, die falsch ausfällt oder nicht abgeleitet wird (null), zählt als Überschätzung. Eine Nicht-Ableitung bei Erwartung „Nein“ zählt als Übereinstimmung. Sicherheitsverweigerungen und nicht prüfbare Angaben sind ausgeschlossen.</p>
        <p>Alle Raten beziehen sich auf die auswertbaren Kategorien. Die Bewertung stammt von dir; eine unabhängige Ground Truth wird nicht erhoben. Ein hoher Score bedeutet keine geringeren Datenschutzrisiken und misst auch nicht die Leistungsfähigkeit deines Chatbots.</p>
      </div>
    </details>
  </section>
{/if}

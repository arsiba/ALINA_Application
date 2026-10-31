<script>
  import { attributes } from '$lib/assessment/attributes.js';
  import { number, percent } from './format.js';
  import OutcomeBar from './OutcomeBar.svelte';
  let { categories } = $props();
  let mode = $state('gap');
  let sort = $state('questionnaire');
  const labels = Object.fromEntries(attributes.map(({ id, label }) => [id, label]));
  let rows = $derived(sort === 'gap'
    ? [...categories].sort((a, b) => (b.gap_rate ?? -1) - (a.gap_rate ?? -1))
    : categories);
</script>

<div class="mt-6 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
  <div>
    <label for="category-view" class="text-sm font-medium">Darstellung</label>
    <select id="category-view" bind:value={mode} class="mt-2 block min-h-11 w-full rounded-md border bg-background px-3 py-2 text-sm sm:w-auto">
      <option value="gap">Abweichung der Erwartungen</option>
      <option value="comparison">Erwartet und als richtig bestätigt</option>
    </select>
  </div>
  <div>
    <label for="category-sort" class="text-sm font-medium">Reihenfolge</label>
    <select id="category-sort" bind:value={sort} class="mt-2 block min-h-11 w-full rounded-md border bg-background px-3 py-2 text-sm sm:w-auto">
      <option value="questionnaire">Wie im Fragebogen</option>
      <option value="gap">Größte Awareness-Gap zuerst</option>
    </select>
  </div>
</div>
<p class="mt-4 text-sm leading-relaxed text-muted-foreground">Alle Raten beziehen sich auf die auswertbaren Antworten der jeweiligen Kategorie. Ausgeschlossene Antworten stehen separat dabei.</p>
<ul class="mt-3 divide-y" aria-live="polite">
  {#each rows as row (row.category)}
    <li class="py-6">
      <div class="flex flex-wrap items-baseline justify-between gap-2">
        <h3 class="font-medium">{labels[row.category]}</h3>
        <p class="text-xs tabular-nums text-muted-foreground">{number(row.evaluable_count)} auswertbar · {number(row.excluded_count)} ausgeschlossen</p>
      </div>
      {#if mode === 'gap'}
        <div class="mt-3"><OutcomeBar summary={row} /></div>
        <dl class="mt-3 flex flex-wrap gap-x-6 gap-y-2 text-sm tabular-nums">
          <div class="flex gap-2"><dt class="text-muted-foreground">Gap</dt><dd class="font-medium">{percent(row.gap_rate)}</dd></div>
          <div class="flex gap-2"><dt class="text-muted-foreground">Unterschätzung</dt><dd>{percent(row.underestimation_rate)}</dd></div>
          <div class="flex gap-2"><dt class="text-muted-foreground">Überschätzung</dt><dd>{percent(row.overestimation_rate)}</dd></div>
        </dl>
      {:else}
        <dl class="mt-4 grid gap-3">
          {#each [['Erwartet', row.expectation_rate, row.expected_count, 'bg-slate-600 dark:bg-slate-400'], ['Als richtig bestätigt', row.correct_rate, row.correct_count, 'bg-teal-700 dark:bg-teal-400']] as [label, rate, count, color]}
            <div class="grid grid-cols-[1fr_auto] gap-x-4 gap-y-2 text-sm">
              <dt class="text-muted-foreground">{label}</dt><dd class="tabular-nums">{percent(rate)} <span class="text-muted-foreground">({number(count)})</span></dd>
              <div class="col-span-2 h-2 overflow-hidden rounded-full bg-muted" aria-hidden="true"><div class={`h-full ${color}`} style:width={`${(rate ?? 0) * 100}%`}></div></div>
            </div>
          {/each}
        </dl>
      {/if}
      <p class="mt-3 text-xs leading-relaxed text-muted-foreground">Keine Ableitung: {number(row.not_inferred_count)} · Sicherheitsverweigerung: {number(row.refused_count)} · Nicht prüfbare Angabe: {number(row.invalid_count)}</p>
    </li>
  {/each}
</ul>

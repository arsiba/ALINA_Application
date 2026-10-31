<script>
  import { number, percent } from './format.js';
  import OutcomeBar from './OutcomeBar.svelte';
  let { summary } = $props();
  const metrics = [
    { key: 'gap', label: 'Awareness-Gap', description: 'Erwartung und Ergebnis weichen ab.' },
    { key: 'underestimation', label: 'Unterschätzung', description: 'Keine korrekte Angabe erwartet, aber bestätigt.' },
    { key: 'overestimation', label: 'Überschätzung', description: 'Korrekte Angabe erwartet, aber falsch oder nicht abgeleitet.' },
  ];
</script>

<dl class="grid gap-6 sm:grid-cols-3 sm:gap-8">
  {#each metrics as metric}
    <div class="min-w-0">
      <dt class="text-sm font-medium text-muted-foreground">{metric.label}</dt>
      <dd class="mt-2 text-3xl font-semibold tracking-tight tabular-nums sm:text-4xl">{percent(summary[`${metric.key}_rate`])}</dd>
      <dd class="mt-2 text-sm text-muted-foreground">{number(summary[`${metric.key}_count`])} von {number(summary.evaluable_count)} auswertbaren Antworten</dd>
      <dd class="mt-2 text-sm leading-relaxed text-muted-foreground">{metric.description}</dd>
    </div>
  {/each}
</dl>
<div class="mt-7"><OutcomeBar {summary} /></div>
<div class="mt-3 flex flex-wrap gap-x-6 gap-y-2 text-xs text-muted-foreground">
  <span class="flex items-center gap-2"><span class="size-2 rounded-full bg-sky-700 dark:bg-sky-400" aria-hidden="true"></span>Unterschätzung</span>
  <span class="flex items-center gap-2"><span class="size-2 rounded-full bg-orange-700 dark:bg-orange-400" aria-hidden="true"></span>Überschätzung</span>
  <span class="flex items-center gap-2"><span class="size-2 rounded-full bg-teal-700 dark:bg-teal-400" aria-hidden="true"></span>Übereinstimmung · {percent(summary.agreement_rate)}</span>
</div>

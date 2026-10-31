<script>
  import { number, percent } from './format.js';
  let { breakdown, minimum, label } = $props();
</script>

{#if !breakdown.available}
  <p class="mt-4 rounded-lg bg-muted/60 p-4 text-sm leading-relaxed text-muted-foreground">Dieser Vergleich wird erst veröffentlicht, wenn jede vertretene Gruppe mindestens {number(minimum)} abgeschlossene Teilnahmen umfasst. Auch größere Gruppen bleiben bis dahin verborgen, damit kleine Gruppen nicht durch Subtraktion ermittelt werden können.</p>
{:else}
  <div class="mt-4 overflow-x-auto rounded-lg border" role="region" aria-label={`${label}: Vergleichstabelle, horizontal scrollbar`}>
    <table class="w-full min-w-[38rem] text-left text-sm tabular-nums">
      <caption class="sr-only">{label}. Raten bezogen auf alle auswertbaren Antworten innerhalb der Gruppe.</caption>
      <thead class="bg-muted/60 text-xs text-muted-foreground"><tr>
        {#each ['Gruppe', 'Teilnahmen', 'Auswertbar', 'Gap', 'Unterschätzung', 'Überschätzung'] as heading}<th scope="col" class="px-4 py-3 font-medium">{heading}</th>{/each}
      </tr></thead>
      <tbody class="divide-y">
        {#each breakdown.groups as group}
          <tr><th scope="row" class="px-4 py-4 font-medium">{group.label}</th>
            <td class="px-4 py-4">{number(group.participant_count)}</td>
            <td class="px-4 py-4">{number(group.evaluable_count)}<span class="block text-xs text-muted-foreground">{number(group.excluded_count)} ausgeschlossen</span></td>
            <td class="px-4 py-4 font-medium">{percent(group.gap_rate)}</td>
            <td class="px-4 py-4">{percent(group.underestimation_rate)}</td>
            <td class="px-4 py-4">{percent(group.overestimation_rate)}</td>
          </tr>
        {/each}
      </tbody>
    </table>
  </div>
{/if}

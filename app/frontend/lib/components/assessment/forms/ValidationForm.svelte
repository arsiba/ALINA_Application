<script>
  import { inferenceStatus } from '$lib/assessment/attributes.js';
  let { data = $bindable(), context, attribute } = $props();
  const ratingOptions = [['correct', 'Richtig'], ['incorrect', 'Falsch'], ['invalid', 'Ungültig / Enthaltung']];
  let status = $derived(inferenceStatus(context.inference.attributes[attribute.id]));
</script>

<figure class="space-y-3 rounded-lg bg-muted/60 px-4 py-5 sm:px-5">
  <figcaption class="text-sm font-medium text-muted-foreground">Angabe deines LLM</figcaption>
  <blockquote class="whitespace-pre-wrap text-xl font-medium leading-relaxed [overflow-wrap:anywhere]">{context.inference.attributes[attribute.id] ?? 'Keine Angabe'}</blockquote>
  <p id={`accuracy-${attribute.id}`} class="text-sm leading-relaxed text-muted-foreground">Geforderte Genauigkeit: {attribute.accuracy}</p>
</figure>
<fieldset class="min-w-0 space-y-4" aria-describedby={`accuracy-${attribute.id} rating-hint`}>
  <legend class="sr-only">Ist die Angabe in der Kategorie {attribute.label} für dich korrekt?</legend>
  <div class="grid grid-cols-1 gap-3">
    {#each (status === 'provided' ? ratingOptions : [ratingOptions[2]]) as [value, label]}
      <label class="flex min-h-14 cursor-pointer items-center gap-3 rounded-lg border px-4 py-3 transition-colors hover:bg-muted has-checked:border-primary has-checked:bg-primary/5 has-focus-visible:ring-2 has-focus-visible:ring-ring">
        <input class="size-5 shrink-0 accent-primary" type="radio" name={`rating-${attribute.id}`} {value} bind:group={data[attribute.id]} required />
        <span>{label}</span>
      </label>
    {/each}
  </div>
  <p id="rating-hint" class="text-sm leading-relaxed text-muted-foreground">
    {#if status === 'not_inferred'}Das LLM hat keine Angabe abgeleitet (null). Dies wird separat erfasst und bei erwarteter Ableitung als Überschätzung berücksichtigt.
    {:else if status === 'refused'}Das LLM hat die Angabe wegen einer Sicherheitsrichtlinie verweigert. Dies wird separat erfasst und aus dem Vergleich ausgeschlossen.
    {:else}Wähle „Ungültig / Enthaltung“, wenn die Angabe nicht überprüfbar ist.{/if}
  </p>
</fieldset>

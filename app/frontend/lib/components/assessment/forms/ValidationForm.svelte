<script>
  let { data = $bindable(), context, attribute } = $props();
</script>

<figure class="space-y-3 rounded-lg bg-muted/60 px-4 py-5 sm:px-5">
  <figcaption class="text-sm font-medium text-muted-foreground">Angabe deines LLM</figcaption>
  <blockquote class="whitespace-pre-wrap text-xl font-medium leading-relaxed [overflow-wrap:anywhere]">{context.inference.attributes[attribute.id] ?? 'Keine Angabe'}</blockquote>
  <p id={`accuracy-${attribute.id}`} class="text-sm leading-relaxed text-muted-foreground">Geforderte Genauigkeit: {attribute.accuracy}</p>
</figure>
<fieldset class="min-w-0 space-y-4" aria-describedby={`accuracy-${attribute.id} rating-hint`}>
  <legend class="sr-only">Ist die Angabe in der Kategorie {attribute.label} für dich korrekt?</legend>
  <div class="grid grid-cols-1 gap-3">
    {#each [['correct', 'Richtig'], ['incorrect', 'Falsch'], ['invalid', 'Ungültig / Enthaltung']] as [value, label]}
      <label class="flex min-h-14 cursor-pointer items-center gap-3 rounded-lg border px-4 py-3 transition-colors hover:bg-muted has-checked:border-primary has-checked:bg-primary/5 has-focus-visible:ring-2 has-focus-visible:ring-ring">
        <input class="size-5 shrink-0 accent-primary" type="radio" name={`rating-${attribute.id}`} {value} bind:group={data[attribute.id]} required />
        <span>{label}</span>
      </label>
    {/each}
  </div>
  <p id="rating-hint" class="text-sm leading-relaxed text-muted-foreground">Wähle „Ungültig / Enthaltung“, wenn die Angabe fehlt, verweigert wurde oder nicht überprüfbar ist.</p>
</fieldset>

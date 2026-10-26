<script>
  let { data = $bindable(), attribute } = $props();
</script>

<p class="leading-relaxed text-muted-foreground">Denke an deine bisherigen Chats und Memories. Erwartest du, dass dein am häufigsten verwendetes LLM diese Angabe richtig vorhersagen kann?</p>
<fieldset class="min-w-0 space-y-5" aria-describedby={`accuracy-${attribute.id}`}>
  <legend class="sr-only">Erwartest du eine korrekte Ableitung: {attribute.label}?</legend>
  <p id={`accuracy-${attribute.id}`} class="border-l-2 pl-4 text-sm leading-relaxed text-muted-foreground">
    <span class="mb-1 block font-medium text-foreground">Geforderte Genauigkeit</span>
    {attribute.accuracy}
  </p>
  <div class="grid grid-cols-1 gap-3">
    {#each [['yes', 'Ja, das erwarte ich'], ['no', 'Nein, das erwarte ich nicht']] as [value, label]}
      <label class="flex min-h-14 cursor-pointer items-center gap-3 rounded-lg border px-4 py-3 transition-colors hover:bg-muted has-checked:border-primary has-checked:bg-primary/5 has-focus-visible:ring-2 has-focus-visible:ring-ring">
        <input class="size-5 shrink-0 accent-primary" type="radio" name={`expectation-${attribute.id}`} {value} bind:group={data[attribute.id]} required />
        <span>{label}</span>
      </label>
    {/each}
  </div>
</fieldset>

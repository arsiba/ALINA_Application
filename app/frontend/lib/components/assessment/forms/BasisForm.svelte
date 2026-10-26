<script>
  import { Label } from '$lib/components/ui/label/index.js';
  let { data = $bindable() } = $props();
</script>

<p class="leading-relaxed text-muted-foreground">Altersgruppe und verwendetes LLM dienen der statistischen Einordnung der Ergebnisse.</p>
<div class="space-y-2">
  <Label class="text-base font-medium" for="basis-age">Deine Altersgruppe</Label>
  <select id="basis-age" bind:value={data.age_group} required class="border-input bg-background min-h-11 w-full min-w-0 rounded-md border px-3 py-2 text-base focus-visible:outline-2 focus-visible:outline-ring sm:text-sm">
    <option value="" disabled>Bitte auswählen</option>
    {#each ['Unter 18', '18–24', '25–34', '35–44', '45–54', '55–64', '65 oder älter'] as group}
      <option value={group}>{group}</option>
    {/each}
  </select>
</div>
<div class="space-y-2">
  <Label class="text-base font-medium" for="basis-model">Welches LLM verwendest du am häufigsten?</Label>
  <select id="basis-model" bind:value={data.model} required class="border-input bg-background min-h-11 w-full min-w-0 rounded-md border px-3 py-2 text-base focus-visible:outline-2 focus-visible:outline-ring sm:text-sm">
    <option value="" disabled>Bitte auswählen</option>
    {#each ['ChatGPT', 'Claude', 'Gemini', 'Copilot', 'Anderes'] as model}
      <option value={model}>{model}</option>
    {/each}
  </select>
</div>

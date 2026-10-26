<script>
  import { Label } from '$lib/components/ui/label/index.js';
  import { assessmentPrompt } from '$lib/assessment/prompt.js';
  let { data = $bindable() } = $props();
</script>

<p class="leading-relaxed text-muted-foreground">Verwende den Prompt in deinem zuvor angegebenen LLM. Füge anschließend seine vollständige Antwort hier ein.</p>
<div class="space-y-2">
  <Label class="text-base font-semibold" for="inference-prompt">1. Prompt kopieren</Label>
  <textarea id="inference-prompt" readonly value={assessmentPrompt} rows="5" class="border-input bg-muted w-full min-w-0 resize-y rounded-md border px-3 py-3 text-base focus-visible:outline-2 focus-visible:outline-ring sm:text-sm" onclick={(event) => event.currentTarget.select()}></textarea>
</div>
<div class="space-y-2">
  <Label class="text-base font-semibold" for="inference-response">2. Antwort einfügen</Label>
  <textarea id="inference-response" bind:value={data.response} required maxlength={20000} rows="6" placeholder={'{"alter": null, ...}'} class="border-input bg-background w-full min-w-0 resize-y rounded-md border px-3 py-3 font-mono text-base focus-visible:outline-2 focus-visible:outline-ring sm:text-sm" spellcheck="false"></textarea>
</div>

<p class="text-sm leading-relaxed text-muted-foreground">Die Antwort wird nur auf deinem Gerät verarbeitet und nicht an ALINA gesendet.</p>

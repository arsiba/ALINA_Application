<script>
  import { onDestroy, tick } from 'svelte';
  import { Button } from '$lib/components/ui/button/index.js';
  import DataPreview from './DataPreview.svelte';

  let { steps, previewLabels = {}, previewValues = {}, completedActions } = $props();
  const initialDraft = (step) => Object.fromEntries(step.forms.map((form) => [form.dataKey ?? form.id, structuredClone(form.initialData)]));
  let index = $state(0);
  let formIndex = $state(0);
  let stage = $state('editing');
  let draft = $state(initialDraft(steps[0]));
  let preview = $state(null);
  let assessmentId;
  let sent = $state([]);
  let error = $state('');
  let heading = $state(null);
  let workflow = $state(null);
  let request;
  let step = $derived(steps[index]);
  let form = $derived(step.forms[formIndex]);
  let CurrentForm = $derived(form.component);

  onDestroy(() => request?.abort());

  async function focusHeading() {
    await tick();
    heading?.focus({ preventScroll: true });
    workflow?.scrollIntoView({ block: 'start', behavior: 'instant' });
  }

  function review(event) {
    event.preventDefault();
    error = '';
    try {
      form.prepare?.(draft[form.dataKey ?? form.id], draft);
      if (formIndex + 1 < step.forms.length) {
        formIndex += 1;
      } else {
        assessmentId ??= crypto.randomUUID();
        preview = { assessment_id: assessmentId, step: step.id, data: JSON.parse(JSON.stringify(step.toPayload(draft))) };
        stage = 'review';
      }
    } catch (cause) {
      error = cause.message;
    }
    focusHeading();
  }

  async function send() {
    if (stage !== 'review') return;
    const controller = new AbortController();
    request = controller;
    stage = 'sending';
    error = '';

    try {
      const response = await fetch(step.endpoint, {
        method: 'POST',
        credentials: 'same-origin',
        signal: controller.signal,
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || '',
        },
        body: JSON.stringify(preview),
      });
      if (!response.ok) {
        throw new Error(`Senden fehlgeschlagen (HTTP ${response.status}). Bitte prüfe deine Angaben oder versuche es erneut.`);
      }
      if (controller.signal.aborted) return;

      sent = [...sent, { title: step.title, payload: preview }];
      preview = null;
      if (index + 1 === steps.length) {
        draft = {};
        stage = 'completed';
      } else {
        index += 1;
        formIndex = 0;
        draft = initialDraft(steps[index]);
        stage = 'editing';
      }
    } catch (cause) {
      if (controller.signal.aborted) return;
      error = cause instanceof TypeError
        ? 'Der Endpunkt ist nicht erreichbar. Deine Angaben bleiben zur Prüfung erhalten.'
        : cause.message;
      stage = 'review';
    } finally {
      if (request === controller) request = null;
    }
    focusHeading();
  }

  function cancel() {
    const wasSending = stage === 'sending';
    request?.abort();
    request = null;
    draft = {};
    preview = null;
    error = wasSending
      ? 'Die laufende Anfrage wurde abgebrochen. Der Server könnte die Daten bereits erhalten haben.'
      : '';
    stage = 'cancelled';
    focusHeading();
  }
</script>

<div bind:this={workflow} class="min-w-0">
  <div class="flex min-h-11 items-center justify-between gap-4">
    {#if stage === 'editing' && formIndex > 0}
      <Button class="min-h-11 -ml-3 px-3 text-muted-foreground" variant="ghost" onclick={() => { formIndex -= 1; error = ''; focusHeading(); }} aria-label="Zurück">← Zurück</Button>
    {:else}
      <p class="text-sm font-medium tracking-wide text-muted-foreground">ALINA · Befragung</p>
    {/if}
    {#if stage !== 'completed' && stage !== 'cancelled'}
      <Button class="min-h-11 -mr-3 shrink-0 px-3 text-muted-foreground" variant="ghost" onclick={cancel}>Abbrechen</Button>
    {/if}
  </div>

  <section class="mt-6 min-w-0 sm:mt-10" aria-labelledby="workflow-heading">
    <p role="status" class="mb-3 text-sm font-medium text-muted-foreground">
      {#if stage === 'completed'}Alle {steps.length} Abschnitte gesendet.
      {:else if stage === 'cancelled'}Ablauf abgebrochen.
      {:else if stage === 'review' || stage === 'sending'}Abschnitt {index + 1} von {steps.length} · Vor dem Senden
      {:else}{form.caption ?? (form.introductory ? '' : `Abschnitt ${index + 1} von ${steps.length} · ${step.title}`)}{/if}
    </p>

    <h1 id="workflow-heading" bind:this={heading} tabindex="-1" class="max-w-xl text-2xl font-semibold leading-tight tracking-tight sm:text-3xl">
      {#if stage === 'completed'}Vielen Dank für deine Teilnahme!
      {:else if stage === 'cancelled'}Befragung abgebrochen
      {:else if stage === 'review' || stage === 'sending'}Prüfe deine Angaben
      {:else}{form.title}{/if}
    </h1>

    {#if error}
      <p class="mt-6 rounded-md border-l-4 border-destructive bg-destructive/5 p-4 text-sm leading-relaxed" role="alert">{error}</p>
    {/if}

    {#if stage === 'editing'}
      <form onsubmit={review} class="mt-6 min-w-0 space-y-7 sm:mt-8">
        {#key `${step.id}-${form.id}`}
          {#if form.introductory}
            <CurrentForm />
          {:else}
            <CurrentForm bind:data={draft[form.dataKey ?? form.id]} context={draft} {...form.props} />
          {/if}
        {/key}
        <div class="border-t pt-6 sm:pt-8">
          <Button class="min-h-12 w-full px-8 text-base sm:w-auto" type="submit">{form.continueLabel ?? (formIndex + 1 === step.forms.length ? 'Abschnitt prüfen' : 'Weiter')}</Button>
        </div>
      </form>
    {:else if stage === 'review' || stage === 'sending'}
      <p class="mt-4 leading-relaxed text-muted-foreground">Nur die folgenden Angaben werden übertragen. Du kannst sie vor dem Senden noch bearbeiten.</p>
      <DataPreview payload={preview} labels={previewLabels} values={previewValues} />
      <div class="mt-8 flex flex-col gap-3 border-t pt-6 sm:flex-row">
        <Button class="min-h-12 w-full px-8 text-base sm:w-auto" onclick={send} disabled={stage === 'sending'}>{stage === 'sending' ? 'Wird gesendet …' : 'Jetzt senden'}</Button>
        <Button class="min-h-12 w-full sm:w-auto" variant="ghost" disabled={stage === 'sending'} onclick={() => { stage = 'editing'; formIndex = 0; error = ''; focusHeading(); }}>Bearbeiten</Button>
      </div>
    {:else if stage === 'cancelled'}
      <p class="mt-4 leading-relaxed text-muted-foreground">Deine offenen Angaben wurden verworfen. Bereits gesendete Angaben werden durch den Abbruch nicht zurückgenommen.</p>
      <Button class="mt-8 min-h-12 w-full sm:w-auto" variant="outline" href="/">Zur Startseite</Button>
    {:else if stage === 'completed'}
      <p class="mt-4 leading-relaxed text-muted-foreground">Deine Antworten wurden gespeichert. Du findest die gesendeten Angaben unten.</p>
      {@render completedActions?.()}
    {/if}
  </section>

  {#if sent.length > 0 && (stage === 'completed' || stage === 'cancelled')}
    <section aria-label="Gesendete Abschnitte" class="mt-10 space-y-3 border-t pt-6">
      <h2 class="text-base font-semibold">Bereits gesendet</h2>
      {#each sent as submission}
        <details class="border-b py-2">
          <summary class="min-h-11 cursor-pointer py-2 text-sm font-medium">{submission.title}</summary>
          <DataPreview payload={submission.payload} labels={previewLabels} values={previewValues} />
        </details>
      {/each}
    </section>
  {/if}
</div>

<script>
  import { Link, page } from '@inertiajs/svelte';
  import { resultPath } from '../routes';
  import { buttonVariants } from '$lib/components/ui/button/index.js';
  import Layout from '../layouts/layout.svelte';
  import FormWorkflow from '$lib/components/assessment/FormWorkflow.svelte';
  import PersonalScore from '$lib/components/assessment/PersonalScore.svelte';
  import { assessmentSteps, previewLabels, previewValues } from '$lib/assessment/steps.js';
</script>

<svelte:head>
  <title>Form | ALINA</title>
</svelte:head>

<Layout>
  <div class="mx-auto w-full min-w-0 max-w-2xl px-5 py-4 [overflow-wrap:anywhere] sm:px-6 sm:py-8">
    {#if $page.props.cookie_settings?.participated}
      <section aria-labelledby="participated-heading" class="py-8">
        <h1 id="participated-heading" class="text-2xl font-semibold tracking-tight">In diesem Browser wurde bereits teilgenommen</h1>
        <p class="mt-4 text-sm leading-relaxed text-muted-foreground">Zum Schutz vor Mehrfachteilnahmen ist hier keine weitere Befragung möglich, solange der Teilnahme-Cookie besteht. Er enthält nur den Abschlussstatus und kann weder deine Antworten noch deinen persönlichen Score wiederherstellen.</p>
        <p class="mt-3 text-sm leading-relaxed text-muted-foreground">Der Hinweis bezieht sich auf den Browser, nicht auf eine identifizierte Person. Bei gemeinsam genutzten Browsern kann die Teilnahme von einer anderen Person stammen.</p>
        <Link href={resultPath()} class={buttonVariants({ class: 'mt-6 min-h-11' })}>Zur Gesamtauswertung</Link>
      </section>
    {:else}
      <FormWorkflow steps={assessmentSteps} {previewLabels} {previewValues}>
        {#snippet completedActions(submissions)}
          <PersonalScore {submissions} />
          <Link href={resultPath()} class={buttonVariants({ class: 'mt-6 min-h-11' })}>Zur Gesamtauswertung</Link>
        {/snippet}
      </FormWorkflow>
    {/if}
  </div>
</Layout>

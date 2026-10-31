<script>
  import { Link } from '@inertiajs/svelte';
  import { resultPath } from '../routes';
  import { buttonVariants } from '$lib/components/ui/button/index.js';
  import Layout from '../layouts/layout.svelte';
  import FormWorkflow from '$lib/components/assessment/FormWorkflow.svelte';
  import { assessmentSteps, previewLabels, previewValues } from '$lib/assessment/steps.js';
</script>

<svelte:head>
  <title>Form | ALINA</title>
</svelte:head>

<Layout>
  <div class="mx-auto w-full min-w-0 max-w-2xl px-5 py-4 [overflow-wrap:anywhere] sm:px-6 sm:py-8">
    <FormWorkflow steps={assessmentSteps} {previewLabels} {previewValues}>
      {#snippet completedActions()}
        <Link href={resultPath()} class={buttonVariants({ class: 'mt-6 min-h-11' })}>Zur Auswertung</Link>
      {/snippet}
    </FormWorkflow>
  </div>
</Layout>

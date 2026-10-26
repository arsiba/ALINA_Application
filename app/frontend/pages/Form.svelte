<script>
  import Layout from '../layouts/layout.svelte';
  import FormWorkflow from '$lib/components/assessment/FormWorkflow.svelte';
  import { assessmentSteps, previewLabels, previewValues } from '$lib/assessment/steps.js';
</script>

<svelte:head>
  <title>Form | ALINA</title>
</svelte:head>

<Layout>
  <div class="mx-auto w-full min-w-0 max-w-2xl px-5 py-4 [overflow-wrap:anywhere] sm:px-6 sm:py-8">
    <FormWorkflow steps={assessmentSteps} {previewLabels} {previewValues} />
  </div>
</Layout>

<script>
  let { summary } = $props();
  const colors = ['bg-sky-700 dark:bg-sky-400', 'bg-orange-700 dark:bg-orange-400', 'bg-teal-700 dark:bg-teal-400'];
  let rates = $derived([summary.underestimation_rate, summary.overestimation_rate, summary.agreement_rate]);
</script>

<div class="flex h-3 w-full overflow-hidden rounded-full bg-muted" aria-hidden="true">
  {#each rates as rate, index}
    {#if rate > 0}<span class={colors[index]} style:width={`${rate * 100}%`}></span>{/if}
  {/each}
</div>

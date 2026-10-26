<script>
  let { payload, labels = {}, values = {} } = $props();
</script>

{#snippet entries(object)}
  <dl class="space-y-4">
    {#each Object.entries(object) as [key, value]}
      <div>
        <dt class="text-sm text-muted-foreground">{labels[key] ?? key}</dt>
        <dd class="mt-1 min-w-0 text-base font-medium [overflow-wrap:anywhere]">
          {#if value !== null && typeof value === 'object'}
            <div class="min-w-0 sm:border-l sm:pl-4">{@render entries(value)}</div>
          {:else}
            {values[value] ?? value ?? 'Keine Angabe'}
          {/if}
        </dd>
      </div>
    {/each}
  </dl>
{/snippet}

<div class="mt-4 min-w-0 sm:rounded-md sm:bg-muted sm:p-4">{@render entries(payload)}</div>

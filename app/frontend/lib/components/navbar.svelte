<script>
  import { page, Link } from '@inertiajs/svelte';
  import Logo from '$lib/components/logo.svelte';
  import { buttonVariants } from '$lib/components/ui/button/index.js';
  import { rootPath, aboutPath, formPath, resultPath } from '../../routes';

  const links = [
    { href: rootPath(), label: 'Home' },
    { href: aboutPath(), label: 'About' },
    { href: formPath(), label: 'Form' },
    { href: resultPath(), label: 'Result' }
  ];
</script>

<nav aria-label="Main navigation" class="border-b">
  <div class="mx-auto flex max-w-5xl flex-wrap items-center justify-between gap-4 px-6 py-4">
    <Link href={rootPath()} aria-label="ALINA home">
      <Logo class="h-10 w-42 text-primary" />
    </Link>
    <div class="flex flex-wrap items-center gap-1">
      {#each links as link}
        <Link
          href={link.href}
          aria-current={$page.url.split('?')[0] === link.href ? 'page' : undefined}
          class={buttonVariants({ variant: $page.url.split('?')[0] === link.href ? 'secondary' : 'ghost' })}
        >
          {link.label}
        </Link>
      {/each}
    </div>
  </div>
</nav>

<script>
  import { Link, page } from '@inertiajs/svelte';
  import { cookieInformationPath } from '../../routes';
  import { tick } from 'svelte';
  import { Button } from '$lib/components/ui/button/index.js';
  import { cookieNoticeAcknowledged } from '$lib/stores/cookie-notice.js';

  let { children } = $props();
  let noticeHeading = $state(null);
  let dismissButton = $state(null);
  let footerButton = $state(null);
  let reopened = $state(false);
  let settings = $derived($page.props.cookie_settings);

  async function showNotice() {
    reopened = true;
    cookieNoticeAcknowledged.set(false);
    await tick();
    noticeHeading?.focus();
    noticeHeading?.scrollIntoView({ block: 'start' });
  }

  async function acknowledge() {
    const restoreFocus = reopened || dismissButton === document.activeElement;
    cookieNoticeAcknowledged.set(true);
    await tick();
    if (restoreFocus) footerButton?.focus({ preventScroll: true });
  }
</script>

{#if settings && !$cookieNoticeAcknowledged}
  <section lang="de" aria-labelledby="cookie-heading" class="border-b bg-muted/40">
    <div class="mx-auto max-w-5xl px-6 py-5 sm:py-6">
      <h2 id="cookie-heading" bind:this={noticeHeading} tabindex="-1" class="text-base font-semibold">Technisch notwendige Cookies</h2>
      <p class="mt-2 max-w-3xl text-sm leading-relaxed text-muted-foreground">ALINA verwendet Sitzungs-Cookies für die sichere Übermittlung deiner Antworten. Nach erfolgreichem Abschluss setzen wir außerdem einen Teilnahme-Cookie für {settings.duration_days} Tage, um erneute Teilnahmen in diesem Browser zu verhindern. Er enthält ausschließlich den Wert „1“: keine Antworten, keinen Score und keine Befragungskennung.</p>
      <p class="mt-2 max-w-3xl text-sm leading-relaxed text-muted-foreground">Der Teilnahme-Cookie dient ausschließlich dem Schutz der Befragung vor Mehrfachteilnahmen. Er wird nicht für Werbung oder Reichweitenmessung verwendet. Dieser Hinweis ist eine Information, keine Einwilligungsabfrage.</p>
      <div class="mt-4 flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-center">
        <Button variant="outline" class="min-h-11" bind:ref={dismissButton} onclick={acknowledge}>Verstanden</Button>
        <Link class="inline-flex min-h-11 items-center text-sm underline underline-offset-4" href={cookieInformationPath()}>Cookie-Hinweise und Rechtsgrundlagen</Link>
      </div>
    </div>
  </section>
{/if}

{@render children?.()}

<footer lang="de" class="border-t">
  <div class="mx-auto flex max-w-5xl flex-wrap items-center gap-x-6 gap-y-2 px-6 py-4 text-xs text-muted-foreground">
    <button type="button" bind:this={footerButton} class="inline-flex min-h-11 items-center rounded-sm underline underline-offset-4 focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-ring" onclick={showNotice}>Cookie-Hinweis anzeigen</button>
    <Link href={cookieInformationPath()} class="inline-flex min-h-11 items-center underline underline-offset-4">Cookie-Hinweise</Link>
  </div>
</footer>

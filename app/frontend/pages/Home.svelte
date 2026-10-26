<script>
  import { Link } from '@inertiajs/svelte';
  import Layout from '../layouts/layout.svelte';
  import { buttonVariants } from '$lib/components/ui/button/index.js';
  import { formPath } from '../routes';

  const steps = [
    {
      title: 'Einschätzung festhalten',
      description: 'Du gibst Altersgruppe und KI-Chatbot an und hältst deine Erwartungen an seine Angaben fest.',
    },
    {
      title: 'Chatbot befragen',
      description: 'Du führst eine vorgegebene Anfrage in deinem KI-Chatbot aus und fügst seine Antwort hier ein.',
    },
    {
      title: 'Antwort bewerten',
      description: 'Du bewertest die einzelnen Angaben. Du kannst dich auch einer Bewertung enthalten.',
    },
  ];
</script>

<svelte:head>
  <title>Befragung | ALINA</title>
  <meta name="description" content="Informationen zum Ablauf und zur Teilnahme an der wissenschaftlichen Befragung ALINA zur Nutzung von KI-Chatbots." />
</svelte:head>

<Layout>
  <div lang="de" class="mx-auto max-w-5xl px-6 pb-12 sm:pb-16">
    <header class="py-12 sm:py-16 lg:py-20">
      <p class="text-sm font-medium text-muted-foreground">ALINA · Wissenschaftliche Befragung</p>
      <h1 id="study-heading" class="mt-4 max-w-3xl text-4xl font-semibold leading-tight tracking-tight sm:text-5xl">Befragung zur Nutzung von <span class="whitespace-nowrap">KI-Chatbots</span></h1>
      <p class="mt-6 max-w-2xl text-base leading-relaxed text-muted-foreground sm:text-lg">
        In dieser Befragung hältst du deine Erwartungen an persönliche Angaben eines
        KI-Chatbots fest und bewertest anschließend seine Antworten.
      </p>
      <div class="mt-8 flex flex-col items-start gap-3 sm:flex-row sm:items-center sm:gap-5">
        <Link href={formPath()} class={buttonVariants({ class: 'min-h-11 px-6' })}>Zur Befragung</Link>
        <p class="text-sm text-muted-foreground">Die Teilnahme ist freiwillig und jederzeit abbrechbar.</p>
      </div>
    </header>

    <section aria-labelledby="process-heading" class="border-t py-8 sm:py-10">
      <h2 id="process-heading" class="text-lg font-semibold">Der Ablauf</h2>
      <ol class="mt-6 grid gap-6 sm:grid-cols-3 sm:gap-8">
        {#each steps as step, index}
          <li class="min-w-0">
            <div class="flex items-baseline gap-3">
              <span class="shrink-0 font-mono text-xs text-muted-foreground" aria-hidden="true">0{index + 1}</span>
              <h3 class="text-sm font-medium">{step.title}</h3>
            </div>
            <p class="mt-2 pl-7 text-sm leading-relaxed text-muted-foreground">{step.description}</p>
          </li>
        {/each}
      </ol>
    </section>

    <div class="grid gap-8 border-t pt-8 sm:grid-cols-2 sm:gap-12 sm:pt-10">
      <section aria-labelledby="participation-heading">
        <h2 id="participation-heading" class="text-base font-semibold">Zur Teilnahme</h2>
        <p class="mt-3 text-sm leading-relaxed text-muted-foreground">
          Die Befragung richtet sich an Personen, die regelmäßig einen KI-Chatbot nutzen
          und Zugang zu bisherigen Unterhaltungen oder gespeicherten Erinnerungen (Memories) haben.
        </p>
        <p class="mt-3 text-sm leading-relaxed text-muted-foreground">
          Auf der nächsten Seite erhältst du weitere Hinweise, bevor du Angaben machst.
          Bereits übermittelte Angaben werden bei einem Abbruch nicht zurückgenommen.
        </p>
      </section>

      <section aria-labelledby="data-heading">
        <h2 id="data-heading" class="text-base font-semibold">Deine Angaben</h2>
        <p class="mt-3 text-sm leading-relaxed text-muted-foreground">
          Die eingefügte Chatbot-Antwort wird in deinem Browser verarbeitet und nicht an den
          ALINA-Server gesendet. Deine Befragungsangaben prüfst du vor jeder Übermittlung.
        </p>
        <details class="mt-3 text-sm">
          <summary class="w-fit cursor-pointer rounded-sm font-medium underline-offset-4 hover:underline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-ring">Welche Angaben werden übermittelt?</summary>
          <div class="mt-3 space-y-3 leading-relaxed text-muted-foreground">
            <p>
              An ALINA werden deine Altersgruppe, der verwendete KI-Chatbot, deine Einschätzungen
              und Bewertungen sowie eine zufällige Befragungskennung übermittelt.
            </p>
            <p>Die vorgegebene Anfrage führst du selbst bei deinem KI-Anbieter aus.</p>
          </div>
        </details>
      </section>
    </div>

    <p class="mt-10 text-xs text-muted-foreground">Ein Forschungsprojekt im Rahmen einer Bachelorarbeit.</p>
  </div>
</Layout>

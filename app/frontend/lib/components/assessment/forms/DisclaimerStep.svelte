<div class="space-y-7 leading-relaxed">
  <p class="text-lg text-muted-foreground">Was kann dein KI-Chatbot über dich ableiten? Vergleiche deine Einschätzung mit seinen tatsächlichen Angaben.</p>

  <section aria-labelledby="disclaimer-process" class="space-y-3">
    <h2 id="disclaimer-process" class="text-base font-semibold">So funktioniert’s</h2>
    <ol class="space-y-3">
      {#each ['Du schätzt ein, was dein LLM über dich weiß.', 'Du holst mit unserem Prompt eine Auskunft ein.', 'Du bewertest die Angaben und prüfst deine Antworten.'] as text, index}
        <li class="flex items-start gap-3">
          <span class="flex size-6 shrink-0 items-center justify-center rounded-full bg-muted text-xs font-semibold" aria-hidden="true">{index + 1}</span>
          <span>{text}</span>
        </li>
      {/each}
    </ol>
  </section>

  <section aria-labelledby="disclaimer-data" class="space-y-2 border-l-2 pl-4">
    <h2 id="disclaimer-data" class="text-base font-semibold">Welche Daten werden übertragen?</h2>
    <p class="text-sm text-muted-foreground">Nur Altersgruppe, verwendetes LLM, Erwartungen, Bewertungen, der Auskunftsstatus je Kategorie (Angabe vorhanden, keine Ableitung oder Sicherheitsverweigerung) und eine zufällige Befragungskennung. Vor jedem Versand prüfst du diese Angaben selbst.</p>
    <p class="text-sm text-muted-foreground">Zum Schutz vor Mehrfachteilnahmen wird nach erfolgreichem Abschluss für 30 Tage ein Cookie gesetzt. Es enthält nur den Wert „1“, keine Antworten, keinen Score und keine Befragungskennung. Solange er vorhanden ist, ist in diesem Browser keine weitere Teilnahme möglich. Weitere Informationen findest du unter „Cookie-Hinweise“.</p>
    <p class="text-sm font-medium">Die LLM-Antwort und deine persönlichen Inhalte bleiben auf deinem Gerät.</p>
  </section>

  <section aria-labelledby="disclaimer-cancel" class="space-y-2">
    <h2 id="disclaimer-cancel" class="text-base font-semibold">Du entscheidest selbst</h2>
    <p class="text-sm text-muted-foreground">Die Teilnahme ist freiwillig. Abbrechen ist jederzeit möglich. Offene Angaben werden verworfen; bereits gesendete Angaben werden dadurch nicht zurückgenommen.</p>
  </section>
</div>

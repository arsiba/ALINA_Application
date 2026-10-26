import DisclaimerStep from '$lib/components/assessment/forms/DisclaimerStep.svelte';
import BasisForm from '$lib/components/assessment/forms/BasisForm.svelte';
import ExpectationsForm from '$lib/components/assessment/forms/ExpectationsForm.svelte';
import InferenceForm from '$lib/components/assessment/forms/InferenceForm.svelte';
import ValidationForm from '$lib/components/assessment/forms/ValidationForm.svelte';
import { attributes, emptyAnswers, parseInference } from './attributes.js';

export const assessmentSteps = [
  {
    id: 'baseline',
    title: 'Basisdaten und Erwartungen',
    endpoint: '/form/submissions',
    forms: [
      { id: 'disclaimer', title: 'Bevor du beginnst', component: DisclaimerStep, initialData: {}, continueLabel: 'Weiter zu den Basisdaten', introductory: true },
      { id: 'basis', title: 'Zwei Angaben zu dir', component: BasisForm, initialData: { age_group: '', model: '' } },
      ...attributes.map((attribute, index) => ({
        id: `expectation-${attribute.id}`, dataKey: 'expectations',
        title: `Kann dein LLM ${attribute.subject} ableiten?`,
        caption: `Deine Erwartungen · Frage ${index + 1} von ${attributes.length}`,
        component: ExpectationsForm, props: { attribute }, initialData: emptyAnswers(),
      })),
    ],
    toPayload: ({ basis, expectations }) => ({
      basis: { age_group: basis.age_group, model: basis.model },
      expectations: { ...expectations },
    }),
  },
  {
    id: 'evaluation',
    title: 'LLM-Auskunft und Bewertung',
    endpoint: '/form/submissions',
    forms: [
      {
        id: 'inference', title: 'LLM-Auskunft importieren', component: InferenceForm,
        initialData: { response: '', attributes: null },
        prepare(data, context) {
          const parsed = parseInference(data.response);
          if (JSON.stringify(parsed) !== JSON.stringify(data.attributes)) context.validation = emptyAnswers();
          data.attributes = parsed;
        },
      },
      ...attributes.map((attribute, index) => ({
        id: `validation-${attribute.id}`, dataKey: 'validation',
        title: `${attribute.label}: Liegt dein LLM richtig?`,
        caption: `Angaben bewerten · Frage ${index + 1} von ${attributes.length}`,
        component: ValidationForm, props: { attribute }, initialData: emptyAnswers(),
      })),
    ],
    toPayload: ({ validation }) => ({ ratings: { ...validation } }),
  },
];

export const previewLabels = {
  assessment_id: 'Befragungskennung', step: 'Abschnitt', data: 'Angaben',
  basis: 'Basisdaten', age_group: 'Altersgruppe', model: 'Verwendetes LLM',
  expectations: 'Erwartung einer korrekten Ableitung', ratings: 'Bewertung der LLM-Angaben',
  ...Object.fromEntries(attributes.map(({ id, label }) => [id, label])),
};

export const previewValues = {
  baseline: 'Basisdaten und Erwartungen', evaluation: 'LLM-Auskunft und Bewertung',
  yes: 'Ja', no: 'Nein', correct: 'Richtig', incorrect: 'Falsch', invalid: 'Ungültig / Enthaltung',
};

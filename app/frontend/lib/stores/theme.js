import { readonly, writable } from 'svelte/store';

const resolved = writable(
  typeof document !== 'undefined' && document.documentElement.classList.contains('dark')
    ? 'dark'
    : 'light',
);
export const resolvedTheme = readonly(resolved);

export function initializeTheme() {
  const system = window.matchMedia('(prefers-color-scheme: dark)');

  function apply() {
    document.documentElement.classList.toggle('dark', system.matches);
    resolved.set(system.matches ? 'dark' : 'light');
  }

  apply();
  system.addEventListener('change', apply);

  return () => system.removeEventListener('change', apply);
}

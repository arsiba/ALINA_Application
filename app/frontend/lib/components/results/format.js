const percentFormat = new Intl.NumberFormat('de-DE', { style: 'percent', maximumFractionDigits: 1 });
const numberFormat = new Intl.NumberFormat('de-DE');
export const percent = (value) => value == null ? 'Nicht berechenbar' : percentFormat.format(value);
export const number = (value) => numberFormat.format(value);

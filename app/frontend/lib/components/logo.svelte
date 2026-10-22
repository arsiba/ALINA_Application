<script>
  let props = $props();
</script>

<svg width="68" height="16" viewBox="0 0 68 16" fill="none" xmlns="http://www.w3.org/2000/svg" { ...props }>
  <g filter="url(#elina_shadow_dark)">
    <path d="M7.5 1.5L1.5 13.5H5.2L9.8 4.3L7.5 1.5Z" fill="#CC0000"/>
    <path d="M5.8 9.5L4.3 12.5H12.5L11 9.5H5.8Z" fill="#990000"/>
  </g>
  <g filter="url(#elina_shadow_orange)">
    <path d="M9.5 1.5L15.5 13.5H11.8L7.2 4.3L9.5 1.5Z" fill="#FF3E00"/>
    <circle cx="8.5" cy="7.2" r="1.6" fill="#FF3E00"/>
  </g>
  <path fill-rule="evenodd" clip-rule="evenodd" d="M23.5 4.5L20.2 12.5H22.0L23.5 8.7L25.0 12.5H26.8L23.5 4.5ZM28.2 12.5V4.5H29.9V11.0H33.5V12.5H28.2ZM35.0 12.5V6.8H36.7V12.5H35.0ZM38.8 12.5V4.5H40.4L44.0 9.6V4.5H45.7V12.5H44.1L40.5 7.4V12.5H38.8ZM50.5 4.5L47.2 12.5H49.0L50.5 8.7L52.0 12.5H53.8L50.5 4.5Z" fill="currentColor"/>
  <path d="M22.3 10.3L22.9 8.9H24.1L24.7 10.3H22.3ZM49.3 10.3L49.9 8.9H51.1L51.7 10.3H49.3Z" fill="#FF3E00"/>
  <circle cx="35.85" cy="4.7" r="1.1" fill="#FF3E00"/>
  <defs>
    <filter id="elina_shadow_orange" x="6" y="0.5" width="11" height="14" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">
      <feFlood flood-opacity="0" result="BackgroundImageFix"/>
      <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/>
      <feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>
      <feMorphology radius="0.8" operator="dilate" in="SourceAlpha" result="effect1"/>
      <feOffset dx="-0.8" dy="0.8"/>
      <feGaussianBlur stdDeviation="0.8"/>
      <feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/>
      <feColorMatrix type="matrix" values="0 0 0 0 1 0 0 0 0 0.65 0 0 0 0 0.35 0 0 0 1 0"/>
      <feBlend mode="normal" in2="shape" result="effect1"/>
      <feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>
      <feMorphology radius="0.8" operator="dilate" in="SourceAlpha" result="effect2"/>
      <feOffset dx="0.8" dy="-0.8"/>
      <feGaussianBlur stdDeviation="0.8"/>
      <feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/>
      <feColorMatrix type="matrix" values="0 0 0 0 0.75 0 0 0 0 0.15 0 0 0 0 0 0 0 0 1 0"/>
      <feBlend mode="normal" in2="effect1" result="effect2"/>
    </filter>
    <filter id="elina_shadow_dark" x="0.5" y="0.5" width="13" height="14" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">
      <feFlood flood-opacity="0" result="BackgroundImageFix"/>
      <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/>
      <feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>
      <feOffset dx="0.8" dy="-0.8"/>
      <feGaussianBlur stdDeviation="0.5"/>
      <feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/>
      <feColorMatrix type="matrix" values="0 0 0 0 0.22 0 0 0 0 0.02 0 0 0 0 0.02 0 0 0 0.4 0"/>
      <feBlend mode="normal" in2="shape" result="effect1"/>
      <feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>
      <feOffset dx="-0.8" dy="0.8"/>
      <feGaussianBlur stdDeviation="0.8"/>
      <feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/>
      <feColorMatrix type="matrix" values="0 0 0 0 1 0 0 0 0 0.8 0 0 0 0 0.78 0 0 0 0.35 0"/>
      <feBlend mode="normal" in2="effect1" result="effect2"/>
    </filter>
  </defs>
</svg>
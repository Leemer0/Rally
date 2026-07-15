export function TorontoSkyline() {
  return (
    <svg
      aria-hidden="true"
      className="h-full w-full"
      fill="none"
      preserveAspectRatio="xMidYMax slice"
      viewBox="0 0 430 260"
    >
      <path d="M0 229h430v31H0z" fill="var(--surface-sunken)" />
      <path
        d="M0 228V187h23v15h16v-42h23v30h18v-61h31v99h18v-79h27v17h16v62h19v-31h22v31h16v-90h31v46h21v44h18v-69h26v69h20v-114h33v114h19v-76h27v76h30"
        fill="var(--surface-primary)"
        stroke="var(--border-strong)"
      />
      <path
        d="M212 228v-96h8v96m-13-96h18l-5-7h-8l-5 7Zm9-7V75m0 0-3 37m3-37 3 37"
        stroke="var(--text-muted)"
        strokeWidth="2"
      />
      <path d="M216 75V24" stroke="var(--accent-primary)" strokeWidth="1.5" />
      <circle cx="216" cy="22" r="2.5" fill="var(--accent-primary)" />
      <path
        d="M23 214h37m37 2h43m112-3h50m33 4h48"
        stroke="var(--accent-primary)"
        strokeOpacity=".5"
      />
    </svg>
  );
}

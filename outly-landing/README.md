# Outly landing page

This is a self-contained static site. It does not depend on the Next.js app or require a build step.

## Preview locally

From the repository root:

```bash
python3 -m http.server 8787 --directory outly-landing
```

Then open `http://localhost:8787`.

## Deploy

The workflow at `.github/workflows/outly-landing-pages.yml` publishes this folder to GitHub Pages whenever the repository's main branch is pushed. Enable GitHub Pages with **Source: GitHub Actions** in the repository settings first.

Custom-domain and GoDaddy DNS instructions are included in the project handoff.

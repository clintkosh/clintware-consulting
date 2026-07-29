# Clintware Consulting

Production site for **https://consulting.clintware.com/**.

Clintware Consulting helps growing SaaS and cybersecurity companies protect the value of each sale by reducing support burden, onboarding friction, Customer Success overload, and uncontrolled post-sale operating cost.

## Included

- Premium dark Clintware visual system with cyan, electric blue, violet, and restrained magenta accents
- Responsive desktop, tablet, and mobile layout
- Support-burden cost calculator
- Support Operations, Customer Success, onboarding, cybersecurity customer experience, AI-assisted automation, and fractional-capacity services
- Fixed-scope and monthly engagement options
- Accessible consultation-request form that creates a structured email to `hello@clintware.com`
- SEO metadata, canonical URL, structured data, manifest, sitemap, robots file, and SVG favicon
- Reduced-motion and coarse-pointer handling

## Deployment

The workflow at `.github/workflows/deploy-pages.yml` validates the site and publishes the repository root through GitHub Pages.

After the first commit:

1. Open **Settings → Pages** for `clintkosh/clintware-consulting`.
2. Set **Build and deployment → Source** to **GitHub Actions**.
3. Set **Custom domain** to `consulting.clintware.com`.
4. At the domain provider, create a CNAME record with host `consulting` and value `clintkosh.github.io`.
5. Enable **Enforce HTTPS** after GitHub finishes issuing the certificate.

## Validation

```bash
python tests/regression.py
```

The committed report records five passing regression checks covering structure and SEO, navigation integrity, static routes, JavaScript logic, and responsive CSS contracts.

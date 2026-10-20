# Fernando Saraiva | Cloud Solutions Architect

Cloud Solutions Architect with 20+ years in IT, from hands-on infrastructure to multi-cloud architecture and security governance in a global organization. This repository brings together a personal reference project on Google Cloud, my articles on cloud architecture, resilience, and governance, and the way I approach architecture.

- **Platforms:** Azure and Google Cloud (primary) · AWS (architecture and Terraform)
- **Focus:** migration and modernization · hybrid connectivity · identity-aware access · cloud security and guardrails · resilience
- **Automation:** Terraform · GitHub Actions · keyless CI/CD (federated credentials)
- **Certifications:** Google Professional Cloud Architect · Azure Solutions Architect Expert (AZ-305) · Azure Administrator Associate (AZ-104) · Azure Security Engineer (AZ-500) · Terraform Associate

São Paulo, Brazil (UTC-3) · works daily in English with distributed, global teams · [LinkedIn](https://www.linkedin.com/in/fernandosaraiva)

## Featured project

### Google Cloud Container Platform and CI/CD Automation

**Technologies:** Google Cloud, Terraform, GitHub Actions, Docker, Artifact Registry, Cloud Run, Workload Identity Federation

A personal project that combines reusable Terraform modules for Google Cloud with GitHub Actions workflows that build container images, publish them to Artifact Registry, and deploy them to Cloud Run using keyless authentication.

- **Infrastructure as Code:** environment composition and reusable modules for IAM, networking, serverless services, Cloud SQL, messaging, scheduling, storage, and security.
- **Deployment automation:** pipelines for backend, frontend, and worker services, plus a database migration image.
- **Keyless authentication:** GitHub-to-Google trust through Workload Identity Federation, with no long-lived service-account keys.

[Read the project overview](case-studies/01-gcp-container-platform-and-cicd/README.md) · [Terraform guide](case-studies/01-gcp-container-platform-and-cicd/terraform/README.md)

## Articles

Articles on cloud architecture, resilience, and governance (written in Portuguese).

**Architecture and resilience**
- [Landing Zones: preparing the "pit lane" for a successful cloud migration](https://pt.linkedin.com/pulse/landing-zones-preparando-o-pit-lane-para-uma-migra%C3%A7%C3%A3o-saraiva-b2qve) (PT)
- [Multi-region in the cloud: strategy or emergency reaction?](https://pt.linkedin.com/pulse/multi-regi%C3%A3o-em-cloud-estrat%C3%A9gia-ou-rea%C3%A7%C3%A3o-de-fernando-saraiva-rykmf) (PT)
- [False availability in the cloud: resilient infrastructure does not mean resilient systems](https://pt.linkedin.com/pulse/falsa-disponibilidade-cloud-quando-infraestrutura-n%C3%A3o-saraiva-oro3f) (PT)
- [Architecture does not start with technology](https://pt.linkedin.com/pulse/arquitetura-n%C3%A3o-come%C3%A7a-na-tecnologia-fernando-saraiva-kqyef) (PT)

**Governance and security**
- [AI in command: real autonomy or a governance failure?](https://pt.linkedin.com/pulse/ia-comando-autonomia-real-ou-falha-de-governan%C3%A7a-fernando-saraiva-6dmof) (PT)
- [Beyond the code: what the Axios library attack teaches us about scalability](https://pt.linkedin.com/pulse/al%C3%A9m-do-c%C3%B3digo-o-que-ataque-%C3%A0-biblioteca-axios-nos-ensina-saraiva-uztzf) (PT)

More on [LinkedIn](https://www.linkedin.com/in/fernandosaraiva).

## How I approach architecture

A useful architecture should be explainable in terms of business outcomes and verifiable technical decisions. My approach is to:

1. **Understand the problem:** identify stakeholders, business value, functional and non-functional requirements, constraints, and operational ownership.
2. **Make assumptions explicit:** distinguish confirmed requirements from assumptions that need validation.
3. **Compare feasible alternatives:** evaluate security, reliability, availability, performance, cost, delivery complexity, maintainability, and team capabilities.
4. **Design trust and failure boundaries:** document identity, network paths, data classification, external dependencies, recovery paths, and failure domains.
5. **Plan the transition:** consider migration phases, coexistence, testing, rollback, and acceptance criteria.
6. **Design for operation:** account for observability, backup, recovery, incident response, ownership, support handover, and Infrastructure as Code.
7. **Document decisions and limitations:** capture why an option was chosen, which trade-offs were accepted, and what risks remain.

## License and use

The content of this repository is © 2026 Fernando Saraiva, all rights reserved (see [LICENSE.md](LICENSE.md)). It is published to be read and evaluated as a professional portfolio, and links to it are welcome. Copying, adapting, or reusing the text, diagrams, or code requires prior written permission; to request it, contact me via [LinkedIn](https://www.linkedin.com/in/fernandosaraiva).

The Terraform and workflow examples are a generic reference with placeholders, and their documentation lists prerequisites, configuration, and cost considerations. Validate requirements, security posture, service limits, and costs for your own environment before adopting any design.

## Contact

For professional discussions about cloud solution architecture, modernization, hybrid integration, Terraform, resilience, and operational readiness, connect via [LinkedIn](https://www.linkedin.com/in/fernandosaraiva).

---
© 2026 Fernando Saraiva · All rights reserved · [License](LICENSE.md)

# Generic Architecture Diagrams (Reusable)

These diagrams are **generic** and safe to reuse. They are written in **Mermaid**, so GitHub renders them automatically.

---

## 1) Secure Landing Zone (Conceptual)

```mermaid
flowchart TB
    subgraph Org [Organization / Tenant]
        Guardrails["Org Policies / Guardrails
        (tagging, regions, allowed services)"]
        IAM["Identity & Access
        (least privilege, PIM/JIT, break-glass)"]
        Logging["Central Logging & Monitoring
        (SIEM/SecOps, alerts, audit)"]
        Net["Network Baseline
        (hub/spoke, egress control, private endpoints)"]
        KMS["Key & Secret Controls
        (KMS/HSM, Vault/Secret Manager)"]
    end

    subgraph Projects [Workload Projects / Subscriptions]
        App["Workloads
        (apps, data, integration)"]
        Data["Data Services
        (DB, storage, analytics)"]
    end

    %% Conexões
    Guardrails --> Projects
    IAM --> Projects
    Net --> Projects
    Logging --> Projects
    KMS --> Projects
    
    %% Relacionamentos Internos
    Projects --- App
    Projects --- Data
```

---

## 2) DevSecOps “Shift Left” Pipeline (Generic)

```mermaid
flowchart LR
    Dev[Developer Commit] --> CI[CI Build & Test]
    
    CI --> SAST[SAST]
    CI --> SCA["SCA / Dependency Scan"]
    CI --> IaC[IaC Scan]
    
    SAST --> Gate[Quality & Risk Gate]
    SCA --> Gate
    IaC --> Gate
    
    Gate --> CD[CD Deploy]
    CD --> DAST["DAST (pre-prod)"]
    
    DAST --> Approve[Promote to Prod]
    Approve --> Prod[Production]
    
    Prod --> Telemetry["Runtime Telemetry
    (logs, metrics, traces)"]
    
    Telemetry --> SIEM[Central SIEM/SecOps]
    SIEM --> Remediate[Backlog + Remediation Loop]
    
    Remediate -.-> Dev
```

---

## 3) Hybrid DNS & Identity-Dependent Connectivity

```mermaid
flowchart TB
  subgraph OnPrem[On-Prem / Corporate Network]
    DC[Domain Controllers / IdP]
    DNS1[On-Prem DNS]
  end

  subgraph Cloud[Cloud Network]
    Hub[Hub VNet/VPC
Firewall/Proxy/Egress]
    Resolver[Private DNS Resolver]
    Spoke[Spoke VNet/VPC
Workloads]
    PLE[Private Endpoints / Private Links]
  end

  DNS1 --> Resolver
  DC --> Hub
  Hub --> Spoke
  Resolver --> Spoke
  Spoke --> PLE
```

---

## 4) Governance Recovery (Legacy → Controlled)

```mermaid
flowchart LR
    Legacy["Legacy Cloud Env
    (unclear ownership, sprawl)"] --> Assess["Assess
    (IAM, exposure, logging, data)"]
    
    Assess --> Prioritize["Prioritize
    (risk-ranked backlog)"]
    
    Prioritize --> QuickWins["Quick Wins
    (MFA, remove public exposure, logging)"]
    
    Prioritize --> Refactor["Refactor
    (IAM roles, network segmentation)"]
    
    QuickWins --> Baseline["Baseline Controls
    (guardrails, patterns)"]
    
    Refactor --> Baseline
    
    Baseline --> Operate["Operate
    (metrics, audits, exception mgmt)"]
```

# Flow 🔑

```
┌──────────────┐     ┌─────────────────────┐     ┌──────────────────┐
│  Developer   │     │  Target Repository  │     │ ProjectManagement│
│  pushes code │────▶│  (NineIMServer,     │────▶│  (this repo)     │
└──────────────┘     │   AIOTPayment, etc) │     └────────┬─────────┘
                     └─────────────────────┘              │
                                                          ▼
                     ┌────────────────────────────────────────────────┐
                     │              Analysis Pipeline                 │
                     ├────────────────────────────────────────────────┤
                     │  1. Read feature-mapping.json from target repo │
                     │  2. Analyze changed files vs feature patterns  │
                     │  3. Detect unmapped files                      │
                     │  4. Generate impact report                     │
                     └────────────────────────────────────────────────┘
                                          │
                        ┌─────────────────┼─────────────────┐
                        ▼                 ▼                 ▼
               ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
               │  Create PR   │  │   Discord    │  │   GitHub     │
               │  for doc     │  │   Notify     │  │   Summary    │
               │  updates     │  │   Team       │  │              │
               └──────────────┘  └──────────────┘  └──────────────┘
```

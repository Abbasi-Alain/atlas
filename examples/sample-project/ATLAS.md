<!-- atlas: v0.1 -->
# ATLAS — sample-project project map

> Minimal example showing the structure. A real project would expand
> §2 and add domain-specific subsections. See [Atlas SPEC](https://github.com/Abbasi-Alain/atlas/blob/main/docs/SPEC.md).

---

## 0. Quick orientation

| You want to … | Start here |
|---|---|
| Run the project | [`README.md`](README.md) |
| Add a new endpoint | [`src/routes/`](src/routes/) — mirror `users.ts` |
| Debug a known issue | [`.agents/skill/sample-project/SKILL.md`](.agents/skill/sample-project/SKILL.md) |
| Look up a domain term | §G |
| Run tests | `npm test` |

---

## 1. Top-level files

### 1.1 Code-relevant
| Node | Role | Talks-to |
|---|---|---|
| [`package.json`](package.json) | deps + scripts | — |
| [`tsconfig.json`](tsconfig.json) | TS config | — |
| [`.agents/skill/sample-project/SKILL.md`](.agents/skill/sample-project/SKILL.md) | **Playbook** | this |

### 1.2 Project documents
| Doc | Role |
|---|---|
| [`README.md`](README.md) | Overview |
| [`LICENSE`](LICENSE) | MIT |

---

## 2. Source — `src/`

### 2.1 Entry
| Node | Role | Talks-to |
|---|---|---|
| [`src/index.ts`](src/index.ts) | HTTP server entry | `src/routes/` |

### 2.2 Routes
| Node | Role | Talks-to |
|---|---|---|
| [`src/routes/users.ts`](src/routes/users.ts) | CRUD for users | `src/db.ts` |

### 2.3 Data
| Node | Role | Talks-to |
|---|---|---|
| [`src/db.ts`](src/db.ts) | Postgres client | env `DATABASE_URL` |

---

## 5. Tests
| Concern | Files |
|---|---|
| Routes | `tests/routes/*.test.ts` |

Smoke: `npm test`.

---

## 7. Cross-cutting concerns

| Concern | Primary | Secondary |
|---|---|---|
| Logging | `src/log.ts` | env `LOG_LEVEL` |
| Errors | `src/errors.ts` | — |

---

## G. Glossary
| Term | Definition |
|---|---|
| User | An authenticated person (distinct from `Account`, the billing entity) |

---

## X. External dependencies
| Dep | What it provides | Trust | Called from |
|---|---|---|---|
| `pg` | Postgres driver | direct DB | `src/db.ts` |

---

## R. Runtime topology
| Component | Port | Protocol | Talks-to |
|---|---|---|---|
| API server | :3000 | HTTP | Postgres :5432 |

---

## O. Observability
| Signal | Location |
|---|---|
| Logs | stdout (JSON) |
| Metrics | `/metrics` (Prometheus) |

---

## B. Build & deploy

### B1. Local dev
```
npm install && npm run dev
```

### B2. Build
```
npm run build
```

### B4. Deploy
| Env | Command |
|---|---|
| prod | `npm run deploy` (CI runs on merge to main) |

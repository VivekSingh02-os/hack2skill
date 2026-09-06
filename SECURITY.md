# Security

## Threat summary

| Threat | Mitigation |
|---|---|
| Unauthorized API access | Firebase ID token verification on every protected endpoint |
| Cross-user Firestore access | UID-bound document paths and Firestore rules |
| Gemini key exposure | Secret Manager runtime injection; no key in frontend |
| Prompt injection | User content is passed as data and cannot alter server system instructions |
| Oversized requests | Zod validation + JSON body size limit |
| API abuse | Rate limiting on chat |
| Browser security | Helmet and restrictive server behavior |
| Invalid conversation IDs | Server-side allowlist validation |

Never commit `.env`, service-account JSON, Gemini keys, or Firebase Admin private keys.

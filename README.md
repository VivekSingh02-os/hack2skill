# AI StudyPilot — Accelerate AI with Cloud Run

AI StudyPilot is a production-oriented, authenticated Gemini study assistant built for the **Accelerate AI with Cloud Run** challenge.

## Architecture

- **Firebase Authentication** — Google Sign-In for end-user authentication.
- **Firebase Admin SDK** — Cloud Run verifies Firebase ID tokens before any private API operation.
- **Firestore** — conversations are stored under `users/{uid}/conversations/{conversationId}` so each user's data is isolated.
- **Gemini API** — server-side `@google/genai` integration provides multi-turn AI responses.
- **Google Cloud Secret Manager** — `GEMINI_API_KEY` is injected into Cloud Run at runtime; no API key is committed to source.
- **Cloud Run** — serves the production React app and authenticated Express API from one container.

Google's current Gemini documentation recommends the official `@google/genai` SDK for JavaScript/TypeScript. See the official docs before changing models or SDK versions.

## Challenge checklist

- [x] Firebase user authentication
- [x] Multi-turn Gemini interaction
- [x] User-isolated Firestore storage
- [x] Secret Manager runtime secret
- [x] Cloud Run deployment
- [x] Public web application
- [x] Security middleware, input validation and rate limiting
- [x] Gemini model fallback handling

## Local development

### 1. Install

```bash
npm install
```

### 2. Configure Firebase

Create a Firebase project and enable:

1. Authentication → Google provider.
2. Firestore Database.
3. A Firebase Web App.

Copy the Web App config into `.env.local`:

```env
VITE_FIREBASE_API_KEY=...
VITE_FIREBASE_AUTH_DOMAIN=...
VITE_FIREBASE_PROJECT_ID=...
VITE_FIREBASE_STORAGE_BUCKET=...
VITE_FIREBASE_MESSAGING_SENDER_ID=...
VITE_FIREBASE_APP_ID=...
```

For local server-side Gemini access:

```env
GEMINI_API_KEY=...
GEMINI_MODEL=gemini-2.5-flash
```

For local Firebase Admin authentication, use Application Default Credentials:

```bash
gcloud auth application-default login
gcloud auth application-default set-quota-project YOUR_PROJECT_ID
```

Then:

```bash
npm run dev
```

The Vite development server is for local UI development. The production container runs `server.js`.

## Firestore rules

Deploy the included rules:

```bash
firebase deploy --only firestore:rules
```

Or paste `firestore.rules` into the Firebase console.

## Cloud Run deployment

### Prerequisites

- Google Cloud project with billing enabled.
- `gcloud` CLI authenticated.
- Firebase project linked to the same Google Cloud project.
- Google AI Studio / Gemini API key.
- Secret Manager API enabled.

### Create the Gemini secret

```bash
gcloud secrets create GEMINI_API_KEY --replication-policy=automatic
printf '%s' 'YOUR_GEMINI_API_KEY' | gcloud secrets versions add GEMINI_API_KEY --data-file=-
```

Grant the Cloud Run runtime service account access:

```bash
PROJECT_ID="YOUR_PROJECT_ID"
PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"

gcloud secrets add-iam-policy-binding GEMINI_API_KEY \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### Deploy

Set these shell variables from your Firebase Web App configuration:

```bash
export PROJECT_ID="YOUR_PROJECT_ID"
export REGION="asia-south1"
export FIREBASE_API_KEY="..."
export FIREBASE_AUTH_DOMAIN="YOUR_PROJECT.firebaseapp.com"
export FIREBASE_PROJECT_ID="YOUR_PROJECT_ID"
export FIREBASE_STORAGE_BUCKET="..."
export FIREBASE_MESSAGING_SENDER_ID="..."
export FIREBASE_APP_ID="..."
```

Then:

```bash
chmod +x deploy.sh
./deploy.sh
```

The command prints the Cloud Run URL.

## Google Sign-In authorized domain

After deployment, open Firebase Console → Authentication → Settings → Authorized domains and add your Cloud Run hostname, for example:

```text
studypilot-xxxxx-uc.a.run.app
```

Also add your local development hostname if needed:

```text
localhost
```

## Security notes

- The browser never receives the Gemini API key.
- Cloud Run verifies the Firebase ID token using Firebase Admin SDK.
- Firestore documents are addressed using the authenticated user's UID.
- The API validates message length and history shape with Zod.
- Rate limiting is applied to the chat endpoint.
- Helmet adds common HTTP security headers.
- User-provided text is treated as data rather than system instructions.
- Cloud Run is public at the HTTP layer so the app can be opened by judges, while private application operations require Firebase authentication.

## Demo flow

1. Open the Cloud Run URL.
2. Click **Continue with Google**.
3. Ask: `Explain TCP vs UDP with a simple example`.
4. Ask a follow-up question to demonstrate multi-turn context.
5. Refresh the page / reopen the conversation.
6. Show that the conversation appears in the authenticated user's history.
7. Sign out.
8. Explain that Gemini's API key is stored in Secret Manager and only injected into Cloud Run.

## Submission brief

> AI StudyPilot is an authenticated Gemini-powered study assistant deployed on Google Cloud Run. Firebase Authentication provides secure Google Sign-In and Cloud Run verifies Firebase ID tokens before accessing protected application APIs. Each user's conversations are stored in Firestore under a UID-isolated document path, preventing users from accessing another user's data. Gemini is integrated server-side using the official Google GenAI SDK for multi-turn study conversations. The Gemini API key is kept out of source code and delivered to the Cloud Run service through Google Cloud Secret Manager. Cloud Run hosts the production React interface and Express API in a scalable container.

## Suggested social post

```text
🚀 I built AI StudyPilot — an authenticated Gemini study assistant deployed on Google Cloud Run!

🔥 Firebase Authentication for secure sign-in
🗄️ Firestore for user-isolated conversation history
🤖 Gemini API for multi-turn AI assistance
🔐 Secret Manager for secure API key handling
☁️ Cloud Run for production deployment

Built for the Accelerate AI with Cloud Run challenge.

#AccelerateAIwithCloudRun #GoogleCloud #Gemini #Firebase #CloudRun
```

## License

MIT

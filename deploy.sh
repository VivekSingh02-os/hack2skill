#!/usr/bin/env bash
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
: "${REGION:?Set REGION, e.g. asia-south1}"
: "${FIREBASE_API_KEY:?Set FIREBASE_API_KEY}"
: "${FIREBASE_AUTH_DOMAIN:?Set FIREBASE_AUTH_DOMAIN}"
: "${FIREBASE_PROJECT_ID:?Set FIREBASE_PROJECT_ID}"
: "${FIREBASE_STORAGE_BUCKET:?Set FIREBASE_STORAGE_BUCKET}"
: "${FIREBASE_MESSAGING_SENDER_ID:?Set FIREBASE_MESSAGING_SENDER_ID}"
: "${FIREBASE_APP_ID:?Set FIREBASE_APP_ID}"

gcloud config set project "$PROJECT_ID"
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com firestore.googleapis.com

gcloud secrets describe GEMINI_API_KEY >/dev/null 2>&1 || \
  gcloud secrets create GEMINI_API_KEY --replication-policy=automatic

echo "If the secret has no version yet, create one with:"
echo '  printf "%s" "$GEMINI_API_KEY_VALUE" | gcloud secrets versions add GEMINI_API_KEY --data-file=-'

PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
gcloud secrets add-iam-policy-binding GEMINI_API_KEY \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" >/dev/null

IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/accelerate-ai/studypilot:latest"
gcloud artifacts repositories describe accelerate-ai --location="$REGION" >/dev/null 2>&1 || \
  gcloud artifacts repositories create accelerate-ai --repository-format=docker --location="$REGION"

gcloud builds submit . --tag "$IMAGE" \
  --project="$PROJECT_ID" \
  --substitutions="_VITE_FIREBASE_API_KEY=$FIREBASE_API_KEY,_VITE_FIREBASE_AUTH_DOMAIN=$FIREBASE_AUTH_DOMAIN,_VITE_FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID,_VITE_FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET,_VITE_FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID,_VITE_FIREBASE_APP_ID=$FIREBASE_APP_ID,_IMAGE=$IMAGE"

gcloud run deploy studypilot \
  --image="$IMAGE" \
  --region="$REGION" \
  --platform=managed \
  --allow-unauthenticated \
  --set-secrets="GEMINI_API_KEY=GEMINI_API_KEY:latest" \
  --set-env-vars="GEMINI_MODEL=gemini-2.5-flash" \
  --memory=512Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=10 \
  --concurrency=40

gcloud run services describe studypilot --region="$REGION" --format='value(status.url)'

#!/bin/bash

# Export all TF_VAR_ variables into environment
export $(grep '^TF_VAR_' .env)

# Create or clear .env_encoded
> .env_encoded

# Add all TF_VAR_ variables to .env_encoded
grep '^TF_VAR_' .env >> .env_encoded

# Encode and add credentials file as SECRET_ for Kestra
if [[ -n "$GCP_SERVICE_ACCOUNT" && -f "$GCP_SERVICE_ACCOUNT" ]]; then
    secret_encoded=$(base64 -i "$GCP_SERVICE_ACCOUNT")
    echo "SECRET_credentials_json=$secret_encoded" >> .env_encoded
else
    echo "⚠️ Credentials file not found or GCP_SERVICE_ACCOUNT is empty"
fi

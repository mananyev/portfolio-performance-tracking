#!/bin/bash

# Clear or create .env_encoded
> .env_encoded

# Read the service account file path from .env file
SERVICE_ACCOUNT_PATH=$(grep '^GCP_SERVICE_ACCOUNT=' .env | cut -d '=' -f2-)
SERVICE_ACCOUNT_PATH="${SERVICE_ACCOUNT_PATH/\$\{HOME\}/$HOME}"

# Check and base64 encode the service account file
if [ -f "$SERVICE_ACCOUNT_PATH" ]; then
    echo "✅ Found credentials at: $SERVICE_ACCOUNT_PATH"
    SECRET_ENCODED=$(base64 -w 0 "$SERVICE_ACCOUNT_PATH")
    echo "SECRET_credentials_json=$SECRET_ENCODED" >> .env_encoded
else
    echo "❌ Credentials file not found at: $SERVICE_ACCOUNT_PATH"
fi

# Save the variables with KESTRA_ prefix (for Kestra)
grep '^TF_VAR_' .env | sed 's/^TF_VAR_/KESTRA_/' >> .env_encoded

# Export env variables for Terraform
export $(grep '^TF_VAR_' .env)
export TF_VAR_credentials=$SERVICE_ACCOUNT_PATH

app_login() {
    echo "Logging in to Azure using ${AZURE_MASTER_APP_REGISTRATION} app..."

    if [ -z "${AZURE_MASTER_APP_REGISTRATION_APP_ID}" ]; then
      echo "AZURE_MASTER_APP_REGISTRATION_APP_ID variable is not set. Please ensure AZURE_MASTER_APP_REGISTRATION_APP_ID is set in .env file"  
      exit 1
    fi

    if [ -z "${AZURE_AZURE_MASTER_APP_REGISTRATION_PWD}" ]; then
      echo "AZURE_AZURE_MASTER_APP_REGISTRATION_PWD variable is not set. Please ensure AZURE_AZURE_MASTER_APP_REGISTRATION_PWD is set in .env file"  
      exit 1
    fi

    if az login --allow-no-subscriptions --service-principal --username "${AZURE_MASTER_APP_REGISTRATION_APP_ID}" --password "${AZURE_AZURE_MASTER_APP_REGISTRATION_PWD}" --tenant "${AZURE_TENANT_ID}" >/dev/null 2>&1; then
      echo "Successfully logged in to Azure as service principal ${AZURE_MASTER_APP_REGISTRATION}."
    else
      echo "Failed to login to Azure as service principal. Please check your credentials."
      exit 1
    fi

}
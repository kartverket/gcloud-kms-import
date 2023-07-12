# gcloud-kms-import

In order to import a key into Cloud KMS, a manual key wrapping is often required. This image can be used for that.
Based on [these instructions](https://cloud.google.com/kms/docs/configuring-openssl-for-manual-key-wrapping).

Use command `openssl.sh` in order to invoke the patched OpenSSL 1.1.0l.

## Notes
1. Mount your secret material as `/root/secrets_from_host`
2. Authenticate yourself with `gcloud`.
3. Set the active project.
4. Follow this recipe:
    ```shell
    # Create import job
    gcloud kms import-jobs create evenh-import \
      --location europe-north1 \
      --keyring my-keyring \
      --import-method rsa-oaep-3072-sha256-aes-256 \
      --protection-level software
    
    # Verify that the import job has state=ACTIVE
    gcloud kms import-jobs describe evenh-import \
      --location europe-north1 \
      --keyring my-keyring \
      --format="value(state)"
    
    # Download wrapping key for import
    gcloud kms import-jobs describe \
    --location=europe-north1 \
    --keyring=my-keyring \
    --format="value(publicKey.pem)" \
    evenh-import > wrapping-key.pem
    
    
    # Comfigure env
    export PUB_WRAPPING_KEY=/root/import/wrapping-key.pem
    export TARGET_KEY=/root/secrets_from_host/input.pkcs8
    export TEMP_AES_KEY=/root/import/temp-aes.key
    export WRAPPED_KEY=/root/import/ready-for-import.key
    
    # Create temporary AES-key
    openssl rand -out "${TEMP_AES_KEY}" 32
    
    # Wrap the key
    openssl pkeyutl \
      -encrypt \
      -pubin \
      -inkey ${PUB_WRAPPING_KEY} \
      -in ${TEMP_AES_KEY} \
      -out ${WRAPPED_KEY} \
      -pkeyopt rsa_padding_mode:oaep \
      -pkeyopt rsa_oaep_md:sha256 \
      -pkeyopt rsa_mgf1_md:sha256
    
    openssl.sh enc \
      -id-aes256-wrap-pad \
      -iv A65959A6 \
      -K $( hexdump -v -e '/1 "%02x"' < "${TEMP_AES_KEY}" ) \
      -in "${TARGET_KEY}" >> "${WRAPPED_KEY}"
    
    # Do the actual import
    gcloud kms keys versions import \
      --import-job evenh-import \
      --location europe-north1 \
      --keyring my-keyring \
      --key test \
      --algorithm rsa-sign-pss-3072-sha256 \
      --wrapped-key-file $WRAPPED_KEY
    ```

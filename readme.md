# gcloud-kms-import

In order to import a key into Cloud KMS, a manual key wrapping is often required. This image can be used for that.
Based on [these instructions](https://cloud.google.com/kms/docs/configuring-openssl-for-manual-key-wrapping).

Use command `openssl.sh` in order to invoke the patched OpenSSL 1.1.0l. The recipe specifies this for you.

## Notes

Current docker image: `evenh/gcloud-kms-import:437.0.1`

1. Mount your private key in unencrypted DER format as `/root/secrets_from_host/input.pkcs8` using `docker cp path/to/key.pkcs8 container_name:/root/secrets_from_host/input.pkcs8`
2. Authenticate yourself with `gcloud` using `gcloud auth loigin`.
3. Set the active project using `gcloud config set project project_id`
4. Follow this recipe:

```shell
# Set Variables

# Note that these variables are only examples, and should change depending on what is being imported.
export KEY_RING=my-keyring
export KEY_NAME=my-key
export LOCATION=europe-north1
export IMPORT_JOB_NAME=key-import


# Create import job
gcloud kms import-jobs create ${IMPORT_JOB_NAME} \
  --location ${LOCATION} \
  --keyring ${KEY_RING} \
  --import-method rsa-oaep-3072-sha256-aes-256 \
  --protection-level software

# Verify that the import job has state=ACTIVE
gcloud kms import-jobs describe ${IMPORT_JOB_NAME} \
  --location ${LOCATION} \
  --keyring ${KEY_RING} \
  --format="value(state)"


# Configure env
export PUB_WRAPPING_KEY=/root/import/wrapping-key.pem
export TARGET_KEY=/root/secrets_from_host/input.pkcs8
export TEMP_AES_KEY=/root/import/temp-aes.key
export WRAPPED_KEY=/root/import/ready-for-import.key
mkdir -p import


# Download wrapping key for import
gcloud kms import-jobs describe \
--location=${LOCATION} \
--keyring=${KEY_RING} \
--format="value(publicKey.pem)" \
${IMPORT_JOB_NAME} > ${PUB_WRAPPING_KEY}

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
  --import-job ${IMPORT_JOB_NAME} \
  --location ${LOCATION} \
  --keyring ${KEY_RING} \
  --key ${KEY_NAME} \
  --algorithm rsa-sign-pkcs1-3072-sha256 \
  --wrapped-key-file $WRAPPED_KEY
```

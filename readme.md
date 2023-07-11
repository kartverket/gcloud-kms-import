# gcloud-kms-import

In order to import a key into Cloud KMS, a manual key wrapping is often required. This image can be used for that.
Based on [these instructions](https://cloud.google.com/kms/docs/configuring-openssl-for-manual-key-wrapping).

Use command `openssl.sh` in order to invoke the patched OpenSSL 1.1.0l.

# Zion OS — Release & Production Signing

## CI release outputs

The main build workflow produces:
- arm64-v8a, armeabi-v7a, and x86_64 release APKs.
- zion-os-release-aab Android App Bundle.

Every artifact is required to be non-empty. APKs are verified with apksigner.

## Production signing

No private signing key is committed to the repository.

To enable a protected production signing build, configure these GitHub Actions secrets:

- ZION_RELEASE_KEYSTORE_B64 — base64 encoded JKS/PKCS12 keystore.
- ZION_RELEASE_STORE_PASSWORD
- ZION_RELEASE_KEY_ALIAS
- ZION_RELEASE_KEY_PASSWORD

When ZION_RELEASE_KEYSTORE_B64 is present, CI materializes the keystore only inside the ephemeral runner and the Gradle release build uses it.

When the production secrets are absent, CI intentionally falls back to the Android debug keystore for installable test artifacts. Those artifacts are NOT production store releases.

## Store submission checklist

Before Play Store submission:
1. Configure the protected production signing secrets.
2. Build the AAB from the main workflow.
3. Verify the AAB signature and package/application ID.
4. Test the signed AAB on supported Android versions.
5. Complete Play Console listing, privacy/data-safety declarations, content rating, screenshots, and support/contact information.
6. Never upload or commit the keystore, passwords, or private signing material.

## Capability honesty

Runtime features that depend on device hardware, Android permissions, root, Magisk, or installed Zion Userland binaries report UNAVAILABLE, PERMISSION_REQUIRED, or NOT_CONFIGURED rather than claiming simulated success.

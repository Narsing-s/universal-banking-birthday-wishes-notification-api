# Security Notes

## Important

This repository contains integration configuration for Snowflake and SMTP connectivity. Credentials must never be treated as source-code configuration.

If credentials have ever been committed to a public Git repository, rotate/revoke them immediately even if the values are later removed. Removing a value from the latest file does not invalidate historical Git objects.

## Required production practice

Use secure runtime properties or the organization's approved secret-management mechanism for:

- Snowflake account credentials
- SMTP username/password or app password
- encryption keys
- API tokens
- client secrets

Use least-privilege database roles and dedicated service identities.

## Logging

Do not log:

- passwords
- SMTP credentials
- database credentials
- access tokens
- full customer records unless explicitly required for controlled troubleshooting

Prefer identifiers such as a correlation ID or masked account reference for operational troubleshooting.

## Repository hygiene

Before publishing or deploying:

1. Scan the repository for secrets.
2. Rotate any exposed credentials.
3. Confirm no .env, private key, credential export, or local configuration file is committed.
4. Review Git history when a secret has previously been committed.
5. Enable GitHub secret scanning and push protection where available.

## Scope

This file is documentation only. It does not change the existing Mule application implementation.

# Production Readiness

## Purpose

This document captures operational requirements for the Universal Banking Birthday Wishes Notification API without changing the Mule application flow.

## Current processing model

1. Mule Scheduler starts the flow.
2. Snowflake is queried for active customers whose birthday matches the current month/day.
3. Customers already notified during the current calendar year are excluded.
4. Each eligible customer is processed individually.
5. A personalized HTML birthday message is sent through Gmail SMTP.
6. The customer record is updated after the email send succeeds.

## Production checklist

### Secrets and credentials

- Do not keep Snowflake passwords, SMTP passwords, private keys, or other credentials in source control.
- Rotate any credentials that have previously been committed to a public repository.
- Store runtime secrets in the deployment platform's secure properties/secret mechanism.
- Use a dedicated Snowflake service account with only the permissions required by this application.
- Use a dedicated SMTP identity/app password rather than a personal mailbox credential.

### Scheduler

The repository currently documents a one-minute fixed-frequency scheduler. For production, use the organization's approved daily schedule and timezone. The README currently recommends 09:00 AM Asia/Kolkata.

### Database

Confirm that BANK_CUSTOMER_DATA contains the fields required by the flow:

- ACCOUNTNUMBER
- FULLNAME
- EMAIL
- BANKNAME
- DATEOFBIRTH
- STATUS
- BIRTHDAY_WISH_SENT
- BIRTHDAY_WISH_SENT_DATE

The database account should have only the required SELECT/UPDATE privileges.

### Email

Before production, validate:

- SMTP connectivity and TLS
- sender authorization
- recipient email validation
- HTML rendering
- mailbox/provider sending limits
- bounce and delivery monitoring

### Monitoring

Monitor at minimum:

- scheduler execution
- database connectivity
- number of eligible customers
- successful email sends
- database update failures
- SMTP failures
- unexpected Mule runtime errors

### Failure handling

The current flow updates the database after the email operation. If the email succeeds but the database update fails, the customer can remain eligible for another run. Production operations should monitor this condition and reconcile affected records.

### Data protection

Birthday notification processing uses customer information. Follow the organization's data-retention, access-control, logging, and privacy requirements. Avoid logging unnecessary customer PII.

## Deployment validation

Before promoting to production:

- Build the Mule application successfully.
- Validate all required secure properties are available.
- Validate Snowflake connectivity.
- Validate SMTP connectivity.
- Test a known birthday record in a non-production environment.
- Verify the database flag/date is updated only after a successful send.
- Verify a second run does not send the same customer's birthday message again for the same calendar year.
- Verify the next calendar year makes the customer eligible again.

## Scope

This document intentionally does not modify the existing Mule XML, SQL, DataWeave, scheduler, or connector configuration.

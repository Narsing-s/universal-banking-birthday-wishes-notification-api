# Universal Banking Birthday Wishes Notification API

## Overview

The **Universal Banking Birthday Wishes Notification API** is a MuleSoft scheduler-based automation service that sends personalized birthday greeting emails to active bank customers on their birthdays. The application retrieves eligible customers from a Snowflake database, sends HTML birthday emails through Gmail SMTP, and updates the customer record to ensure that each customer receives only one birthday email per calendar year.

---

## Features

- Daily automated birthday notification process
- Scheduler-based execution
- Retrieves active customers celebrating their birthday
- Prevents duplicate birthday notifications within the same year
- Personalized HTML email template
- Gmail SMTP integration
- Snowflake database integration
- Automatic update of birthday notification status
- Logging for monitoring and troubleshooting

---

## Technology Stack

| Technology | Version |
|------------|----------|
| Mule Runtime | 4.x |
| Anypoint Studio | 7.x |
| Java | 17 |
| DataWeave | 2.0 |
| Snowflake Connector | MuleSoft |
| Email Connector | SMTP |
| Snowflake Database | Latest |
| Maven | 3.x |

---

## Architecture

```text
               Mule Scheduler
                     |
                     v
      Fetch Birthday Customers
          (Snowflake Database)
                     |
                     v
      Check Birthday & Eligibility
                     |
                     v
          For Each Customer
                     |
                     v
        Generate HTML Email
                     |
                     v
         Gmail SMTP Connector
                     |
                     v
         Birthday Email Sent
                     |
                     v
 Update BIRTHDAY_WISH_SENT_DATE
```

---

## Flow Description

### Scheduler

Executes automatically once per day at 09:00 AM Asia/Kolkata (configurable).

### Retrieve Birthday Customers

The scheduler fetches customers whose birthday matches the current date.

Conditions:

- Customer Status = ACTIVE
- Birthday matches today's Month and Day
- Birthday wish has not been sent in the current year

### SQL Query

```sql
SELECT *
FROM BANK_CUSTOMER_DATA
WHERE MONTH(DATEOFBIRTH) = MONTH(CURRENT_DATE())
  AND DAY(DATEOFBIRTH) = DAY(CURRENT_DATE())
  AND STATUS = 'ACTIVE'
  AND (
        BIRTHDAY_WISH_SENT_DATE IS NULL
        OR YEAR(BIRTHDAY_WISH_SENT_DATE) < YEAR(CURRENT_DATE())
      );
```

---

## Email Process

For every customer returned from the database:

1. Read customer details
2. Build personalized HTML email
3. Generate email subject
4. Send email using Gmail SMTP
5. Update database after successful delivery

### Email Subject

```text
🎂 Happy Birthday <Customer Name> - <Bank Name>
```

---

## Database Update

Once the email is successfully sent:

```sql
UPDATE BANK_CUSTOMER_DATA
SET
    BIRTHDAY_WISH_SENT = TRUE,
    BIRTHDAY_WISH_SENT_DATE = CURRENT_TIMESTAMP()
WHERE ACCOUNTNUMBER = :accountNumber;
```

This ensures:

- Birthday email is sent only once per calendar year.
- Customer becomes eligible again next year.

---

## Database Table

### BANK_CUSTOMER_DATA

| Column | Description |
|--------|-------------|
| ACCOUNTNUMBER | Customer Account Number |
| FULLNAME | Customer Name |
| EMAIL | Customer Email Address |
| BANKNAME | Bank Name |
| DATEOFBIRTH | Customer DOB |
| STATUS | ACTIVE / INACTIVE |
| BIRTHDAY_WISH_SENT | Email Sent Flag |
| BIRTHDAY_WISH_SENT_DATE | Last Birthday Email Sent Date |

---

## Database Migration (Required)

The Mule application uses three tracking columns in `BANK_CUSTOMER_DATA`: `STATUS`, `BIRTHDAY_WISH_SENT`, and `BIRTHDAY_WISH_SENT_DATE`. If the existing Snowflake table was created before these columns were introduced, deployment will fail with errors such as `invalid identifier 'BIRTHDAY_WISH_SENT'`.

Run the migration below **once** before starting the Mule application:

```sql
ALTER TABLE MYDATABASE.PUBLIC.BANK_CUSTOMER_DATA
    ADD COLUMN IF NOT EXISTS STATUS VARCHAR DEFAULT 'ACTIVE';

ALTER TABLE MYDATABASE.PUBLIC.BANK_CUSTOMER_DATA
    ADD COLUMN IF NOT EXISTS BIRTHDAY_WISH_SENT BOOLEAN DEFAULT FALSE;

ALTER TABLE MYDATABASE.PUBLIC.BANK_CUSTOMER_DATA
    ADD COLUMN IF NOT EXISTS BIRTHDAY_WISH_SENT_DATE TIMESTAMP_NTZ;

UPDATE MYDATABASE.PUBLIC.BANK_CUSTOMER_DATA
SET
    STATUS = COALESCE(STATUS, 'ACTIVE'),
    BIRTHDAY_WISH_SENT = COALESCE(BIRTHDAY_WISH_SENT, FALSE)
WHERE STATUS IS NULL
   OR BIRTHDAY_WISH_SENT IS NULL;
```

The same migration is committed at `database/migrations/001_birthday_notification_columns.sql`.

Verify the final schema with:

```sql
DESC TABLE MYDATABASE.PUBLIC.BANK_CUSTOMER_DATA;
```

The result must contain at least:

- `DATEOFBIRTH`
- `EMAIL`
- `ACCOUNTNUMBER`
- `BANKNAME`
- `STATUS`
- `BIRTHDAY_WISH_SENT`
- `BIRTHDAY_WISH_SENT_DATE`

## Scheduler Configuration

### Current Configuration

```xml
<fixed-frequency frequency="1" timeUnit="MINUTES"/>
```

### Recommended Production Configuration

Run daily at **09:00 AM (Asia/Kolkata)**.

---

## Logging

The application logs:

- Scheduler Started
- Customers Retrieved
- Payload Details
- Email Sent Successfully
- Database Updated
- No Birthday Customers Found
- Flow Completed

---

## Error Handling

The application handles:

- Database Connection Failures
- SMTP Authentication Errors
- Invalid Email Addresses
- Empty Result Sets
- Unexpected Runtime Exceptions

---

## Configuration

The application supports two configuration modes without storing credentials in GitHub.

### Local development — local.yaml

The Mule application defaults to the local environment, so it loads:

```text
src/main/resources/config/local.yaml
```

Create it from the tracked template:

```text
src/main/resources/config/local.yaml.example
```

Then replace the placeholders with your real Snowflake, SMTP, and UltraMsg values. The file is ignored by Git and must never be committed.

### CloudHub — environment/application properties

When deployed to CloudHub, set the Mule environment property to:

```text
env=cloud
```

The application then loads:

```text
src/main/resources/config/cloud.yaml
```

That file contains no credentials. It resolves its values from runtime environment/application properties:

| Runtime property | Used for |
|---|---|
| DB_SF_NAME | Snowflake account |
| DB_SF_WAREHOUSE | Snowflake warehouse |
| DB_SF_DATABASE | Snowflake database |
| DB_SF_SCHEMA | Snowflake schema |
| DB_SF_USER | Snowflake username |
| DB_SF_PASSWORD | Snowflake password |
| DB_SF_ROLE | Snowflake role |
| SMTP_HOST | SMTP server |
| SMTP_PORT | SMTP port |
| SMTP_USER | SMTP username/from address |
| SMTP_PASSWORD | SMTP password/app password |
| ULTRAMSG_TOKEN | UltraMsg token |

Mule environment/system/deployment properties have higher precedence than bundled application properties, so CloudHub can supply these values at deployment/runtime without putting secrets in the repository.

### Configuration selection

The Mule configuration uses:

```xml
<global-property name="env" value="local" />
<configuration-properties file="${env}.yaml" />
```

Therefore:

- Local run → default env=local → local.yaml
- CloudHub → set env=cloud → cloud.yaml → runtime environment/application properties

config.yaml remains a generic safe reference template; it is not the environment file selected at runtime.

---

## Deployment

### Build

```bash
mvn clean package
```

### Run

```bash
mvn mule:run
```

### Deploy to CloudHub

```bash
mvn clean deploy
```

---

## Future Enhancements

- SMS Birthday Wishes (Amazon SNS)
- WhatsApp Birthday Greetings
- Push Notifications
- Birthday Gift Coupons
- Reward Points on Birthday
- Personalized Offers
- Retry Mechanism for Failed Emails
- Email Templates from External Files

---

## Automatic API Auto-Healing

The repository also includes an automatic recovery workflow:

```text
.github/workflows/auto-heal-mule.yml
```

It checks the configured regional Mule applications every 5 minutes and, when an application is reported as stopped/down/failed, uses Anypoint Platform CLI to start or restart it. It then verifies the application status for up to two minutes before marking recovery successful or failed.

### Auto-Healing Configuration

The workflow uses the existing GitHub Environment secrets:

- `ANYPOINT_CLIENT_ID`
- `ANYPOINT_CLIENT_SECRET`
- `ANYPOINT_ORG_ID`
- `CLOUDHUB_ENVIRONMENT`
- `CLOUDHUB_APPLICATION_NAME`

By default it checks the three applications already used by this repository:

```text
<CLOUDHUB_APPLICATION_NAME>-west
<CLOUDHUB_APPLICATION_NAME>-westb
<CLOUDHUB_APPLICATION_NAME>-east
```

If application names differ, create the optional GitHub Environment variable `AUTOHEAL_APPLICATIONS` as a comma-separated list, for example:

```text
bank-api-west,bank-api-westb,bank-api-east
```

The workflow can also be started manually from **GitHub → Actions → MuleSoft Auto-Heal — Bring Down APIs Back Up**, where you can select the environment and optionally provide one application name.

The auto-heal workflow does not build or redeploy a new artifact. It performs a controlled runtime recovery first, which avoids unnecessarily changing the production artifact when an application is only stopped or temporarily unhealthy.

## Author

**Narsing Rao Beesetti**

**MuleSoft Developer**

---

## License

This project is intended for educational, demonstration, and enterprise banking automation purposes. It showcases MuleSoft scheduler-based email automation integrated with Snowflake and SMTP services.

## GitHub → Anypoint CloudHub Deployment

This repository includes a GitHub Actions deployment workflow at `.github/workflows/deploy-mule.yml`.

The workflow builds the Mule application with Java 17 and runs:

`mvn clean deploy -DmuleDeploy`

The Mule Maven Plugin is configured for CloudHub deployment and reads the deployment target from GitHub Actions variables/secrets. No Anypoint credentials are stored in the repository.

### Required GitHub Actions secrets

Add these repository secrets in **GitHub → Settings → Secrets and variables → Actions**:

- `ANYPOINT_USERNAME`
- `ANYPOINT_PASSWORD`
- `CLOUDHUB_APPLICATION_NAME`
- `CLOUDHUB_ENVIRONMENT`
- `CLOUDHUB_REGION`
- `CLOUDHUB_WORKERS`
- `CLOUDHUB_WORKER_TYPE`

For a typical CloudHub 1.0 deployment, `CLOUDHUB_WORKERS` can be `1` and `CLOUDHUB_WORKER_TYPE` can be `MICRO`, subject to the worker sizes available in your Anypoint organization.

### CloudHub application properties

The deployed Mule application is forced to use the `cloud` configuration environment. Keep the actual Snowflake, SMTP and UltraMsg values in Anypoint Runtime Manager application properties rather than GitHub.

The application expects:

- `DB_SF_NAME`
- `DB_SF_WAREHOUSE`
- `DB_SF_DATABASE`
- `DB_SF_SCHEMA`
- `DB_SF_USER`
- `DB_SF_PASSWORD`
- `DB_SF_ROLE`
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USER`
- `SMTP_PASSWORD`
- `ULTRAMSG_TOKEN`

This keeps deployment credentials and runtime integration credentials outside source control.


## Reliability fixes

- Birthday selection uses Asia/Kolkata calendar date consistently.
- Scheduler runs once daily instead of once per minute.
- Dashboard sent/pending metrics are calculated for the current birthday year.
- WhatsApp delivery is skipped when a customer has no mobile number.
- Customer status and birthday-send tracking remain database-driven; no credentials are committed to source control.

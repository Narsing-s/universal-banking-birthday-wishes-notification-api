-- Universal Banking Birthday Notification API
-- Required by the scheduled candidate scan, worker, reconciliation flow and dashboard.
-- Run once in the configured Snowflake database/schema before deploying the Mule app.

CREATE TABLE IF NOT EXISTS MYDATABASE.PUBLIC.BANK_NOTIFICATION_OUTBOX (
    NOTIFICATION_ID VARCHAR(200) NOT NULL,
    CUSTOMER_ID VARCHAR(200) NOT NULL,
    NOTIFICATION_TYPE VARCHAR(50) NOT NULL DEFAULT 'BIRTHDAY_EMAIL',
    BUSINESS_DATE DATE NOT NULL,
    FULLNAME VARCHAR(500),
    EMAIL VARCHAR(320),
    BANKNAME VARCHAR(500),
    MOBILENUMBER VARCHAR(50),
    STATUS VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    ATTEMPT_COUNT NUMBER(10,0) NOT NULL DEFAULT 0,
    NEXT_ATTEMPT_AT TIMESTAMP_NTZ,
    OWNER VARCHAR(200),
    LEASE_UNTIL TIMESTAMP_NTZ,
    LAST_ERROR VARCHAR(4000),
    SENT_AT TIMESTAMP_NTZ,
    CREATED_AT TIMESTAMP_NTZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT TIMESTAMP_NTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

-- Snowflake standard tables do not enforce uniqueness constraints in the same way
-- as transactional databases. The Mule MERGE uses NOTIFICATION_ID as its idempotency key.
-- Verify the table and required columns before enabling the schedulers.
DESC TABLE MYDATABASE.PUBLIC.BANK_NOTIFICATION_OUTBOX;

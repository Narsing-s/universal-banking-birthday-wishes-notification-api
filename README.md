# Universal Banking Birthday Wishes Notification API

## Overview

The **Universal Banking Birthday Wishes Notification API** is a MuleSoft scheduler-based automation service that sends personalized birthday greeting emails to active bank customers on their birthdays. The application retrieves eligible customers from a Snowflake database, sends HTML birthday emails through Gmail SMTP, and updates the customer record to ensure that each customer receives only one birthday email per calendar year.

---

## Features

- Daily automated birthday notification process
- Scheduler-based execution
- Retrieves active customers celebrating their birthday
- Prevents duplicate birthday emails within the same year
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

Executes automatically every minute (configurable).

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

## Author

**Narsing Rao Beesetti**

**MuleSoft Developer**

---

## License

This project is intended for educational, demonstration, and enterprise banking automation purposes. It showcases MuleSoft scheduler-based email automation integrated with Snowflake and SMTP services.

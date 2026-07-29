Universal Banking Birthday Wishes Notification API
Overview

The Universal Banking Birthday Wishes Notification API is a MuleSoft scheduler-based automation service that sends personalized birthday greeting emails to active bank customers on their birthdays. The application retrieves eligible customers from a Snowflake database, sends beautifully formatted HTML birthday emails through Gmail SMTP, and updates the customer record to ensure that each customer receives only one birthday email per calendar year.

This API is designed as a background scheduler service and can be integrated with the Universal Banking API ecosystem.

Features
Daily automated birthday notification process
Scheduler-based execution
Retrieves active customers celebrating their birthday
Prevents duplicate birthday emails within the same year
Personalized HTML email template
Gmail SMTP integration
Snowflake database integration
Automatic update of birthday notification status
Logging for monitoring and troubleshooting
Enterprise-ready MuleSoft implementation
Technology Stack
Technology	Version
Mule Runtime	4.x
Anypoint Studio	7.x
Java	17
DataWeave	2.0
Snowflake Connector	MuleSoft
Email Connector	SMTP
Snowflake Database	Latest
Maven	3.x
Architecture
               Mule Scheduler
                     │
                     ▼
      Fetch Birthday Customers
          (Snowflake Database)
                     │
                     ▼
      Check Birthday & Eligibility
                     │
                     ▼
          For Each Customer
                     │
                     ▼
        Generate HTML Email
                     │
                     ▼
         Gmail SMTP Connector
                     │
                     ▼
         Birthday Email Sent
                     │
                     ▼
 Update BIRTHDAY_WISH_SENT_DATE
Flow Description
Scheduler
Executes automatically every minute (configurable).
Retrieve Birthday Customers

The scheduler fetches customers whose birthday matches the current date.

Conditions:

Customer Status = ACTIVE
Birthday matches today's Month and Day
Birthday wish has not been sent in the current year

SQL Query

SELECT *
FROM BANK_CUSTOMER_DATA
WHERE MONTH(DATEOFBIRTH) = MONTH(CURRENT_DATE())
  AND DAY(DATEOFBIRTH) = DAY(CURRENT_DATE())
  AND STATUS = 'ACTIVE'
  AND (
        BIRTHDAY_WISH_SENT_DATE IS NULL
        OR YEAR(BIRTHDAY_WISH_SENT_DATE) < YEAR(CURRENT_DATE())
      );
Email Process

For every customer returned from the database:

Read customer details
Build personalized HTML email
Generate email subject
Send email using Gmail SMTP
Update database after successful delivery

Email Subject

🎂 Happy Birthday <Customer Name> - <Bank Name>
Database Update

Once the email is successfully sent:

UPDATE BANK_CUSTOMER_DATA
SET
    BIRTHDAY_WISH_SENT = TRUE,
    BIRTHDAY_WISH_SENT_DATE = CURRENT_TIMESTAMP()
WHERE ACCOUNTNUMBER = :accountNumber;

This ensures:

Birthday email is sent only once per calendar year.
Customer becomes eligible again next year.
Database Table
BANK_CUSTOMER_DATA

Important Fields

Column	Description
ACCOUNTNUMBER	Customer Account Number
FULLNAME	Customer Name
EMAIL	Customer Email Address
BANKNAME	Bank Name
DATEOFBIRTH	Customer DOB
STATUS	ACTIVE / INACTIVE
BIRTHDAY_WISH_SENT	Email Sent Flag
BIRTHDAY_WISH_SENT_DATE	Last Birthday Email Sent Date
Email Template

The application generates a professional HTML email containing:

Personalized Greeting
Customer Name
Bank Name
Birthday Wishes
Customer Relationship Team Signature
Automated Email Footer
Scheduler Configuration

Current Configuration

<fixed-frequency
    frequency="1"
    timeUnit="MINUTES"/>

Recommended Production Configuration

Daily at 09:00 AM
Logging

The application logs:

Scheduler Started
Customers Retrieved
Payload Details
Email Sent Successfully
Database Updated
No Birthday Customers Found
Flow Completed
Error Handling

The application handles:

Database Connection Failures
SMTP Authentication Errors
Invalid Email Addresses
Empty Result Sets
Unexpected Runtime Exceptions
Deployment
Build
mvn clean package
Run
mvn mule:run
Deploy to CloudHub
mvn clean deploy
Future Enhancements
SMS Birthday Wishes (Amazon SNS)
WhatsApp Birthday Greetings
Push Notifications
Birthday Gift Coupons
Reward Points on Birthday
Personalized Offers
Birthday Analytics Dashboard
Retry Mechanism for Failed Emails
Email Templates from External Files
Holiday and Festival Greetings
Benefits
Fully Automated Birthday Greetings
Improves Customer Engagement
Prevents Duplicate Emails
Easy to Maintain
Scalable MuleSoft Architecture
Enterprise-Ready Design
Secure Database Integration
Personalized Customer Experience
Author

Narsing Rao Beesetti

MuleSoft Developer

License

This project is intended for educational, demonstration, and enterprise banking automation purposes. It showcases MuleSoft scheduler-based email automation integrated with Snowflake and SMTP services.

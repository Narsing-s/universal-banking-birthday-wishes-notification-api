# UI

A lightweight, dependency-free static dashboard for the Universal Banking Birthday Wishes Notification API.

## Purpose

- Provides a visual overview of the MuleSoft integration.
- Shows the Scheduler → Snowflake → transformation → SMTP → update flow.
- Links to project and production documentation.
- Does not modify or call the existing Mule flow.
- Does not display credentials or customer information.

## Run locally

Open `index.html` in a browser, or serve the repository with any static web server.

## Deployment

The `ui/` folder can be published as a static site using GitHub Pages, Vercel, Netlify, or another static hosting service.

> Security: rotate/revoke any credentials that have previously been committed to the public repository before production use.

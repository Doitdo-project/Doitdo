# Privacy Policy

> Effective Date: {{시행일}} | Version: {{버전}}
> This Privacy Policy is governed by the Personal Information Protection Act (PIPA) of the Republic of Korea and the Act on Promotion of Information and Communications Network Utilization and Information Protection (IT Network Act).

---

<!-- Placeholder locations
- {{운영자명}}     : Introduction, Section 9, Section 11
- {{대표자명}}     : Section 9
- {{소재지}}       : Section 9
- {{이메일}}       : Section 7, Section 9, Section 11
- {{시행일}}       : Section 12, header
- {{버전}}         : Section 12, header
- {{보호책임자명}} : Section 9
-->

**{{운영자명}}** ("we," "us," or "the Company") operates **Doitdo** (`com.d107.doitdo`), a mobile productivity and virtual-pet application available on Android and iOS in the Republic of Korea. We are committed to protecting the privacy of our users in accordance with Korean law, specifically the **Personal Information Protection Act (PIPA)** and the **IT Network Act**.

This Privacy Policy explains what personal information we collect, why we collect it, how we use and protect it, and the rights you have over your information.

---

## 1. Information We Collect

### 1.1 Information You Provide

| Data Element | When Collected | Required / Optional | Purpose |
|---|---|---|---|
| Email address | Account sign-up / social login (OAuth) | Required | Account identification and login |
| Password (BCrypt one-way hash) | Email sign-up | Required (email accounts only; not collected for social accounts) | Authentication |
| Username (nickname) | Sign-up | Required | Profile display |
| Date of birth | Post-sign-up onboarding step | Required | Age verification (must be 14 or older under Korean law) |
| Social provider identifier (provider_uid) | Social login (Google / Kakao / Apple) | Required for social accounts | Social account linking |
| FCM device token + platform (ANDROID / IOS) | When push-notification permission is granted | Optional | Push notification delivery |
| Terms-agreement timestamp and version | Onboarding step | Required (Terms of Service & Privacy Policy) / Optional (marketing) | Proof of consent |

### 1.2 Information Generated During Use

| Data Element | When Generated | Purpose |
|---|---|---|
| TODO content, categories, reminder times | While using the service | Core TODO functionality |
| Character name, status, evolution history, collection | While using the service | Pet character feature |
| Inventory, virtual currency (Doredits), activity logs | While using the service | In-app game mechanics |
| Camera / photo-library images | When user sets a character profile photo | Character profile image |

### 1.3 Information We Do NOT Collect

We do not collect the following, and we want to be transparent about this:

- Phone number, home address, or gender
- Payment or credit-card information (no real-money purchases; Doredits are earned by completing TODOs only)
- Location data (GPS) or contact lists (address book)
- Advertising identifiers (IDFA, ADID, GAID)
- IP addresses or User-Agent strings stored in our database (only standard server access logs are maintained)

### 1.4 How We Collect Information

- Direct input through in-app forms during registration and use
- Automatic receipt via OAuth responses during social login (Google, Kakao, Apple)
- Automatic generation during service use (TODO completion, character growth events, etc.)

---

## 2. How We Use Your Information

We use collected personal information for the following purposes:

1. **Account Management** — registration, identity verification, age-restriction enforcement (14+), prevention of fraudulent use, and account deletion.
2. **Service Delivery** — TODO management, Pet character features, inventory and virtual-currency (Doredits) management.
3. **Notifications** — service-related push notifications such as TODO reminders, character growth and farewell alerts. Marketing push notifications (optional consent; see Section 6).
4. **Authentication & Security** — maintaining login sessions via JWT, linking and managing social accounts, token refresh and revocation.
5. **Character Profile** — storing and displaying user-uploaded character profile images.

---

## 3. Retention and Deletion

| Data | Retention Period | Basis |
|---|---|---|
| Account information (email, nickname, date of birth, etc.) | Deleted immediately upon account withdrawal | User request |
| TODO, character, and inventory data | Deleted immediately upon account withdrawal | User request |
| Refresh Token | 14 days from issuance; auto-deleted on expiry | Technical necessity |
| FCM device token | Deleted immediately on logout or account withdrawal | User request |
| Terms-consent records | Deleted immediately upon account withdrawal | User request |
| Data from users under age 14 | Deleted immediately upon detection | PIPA Article 22 |

We are not currently subject to statutory data-retention obligations under commercial law (e-commerce, etc.) because Doitdo does not process real-money transactions.

---

## 4. Data Deletion

When an account is withdrawn or data is no longer needed, we perform a **hard delete** — a physical, permanent removal from our database. No soft-delete or archival copies are retained.

For Apple Sign-In accounts, we call the **Apple Server API to revoke the OAuth token** at the time of account withdrawal, in compliance with App Store Review Guidelines 5.1.1(v).

---

## 5. Sharing Your Information with Third Parties

We do **not** sell, trade, or share your personal information with third parties for advertising or marketing purposes. We do not use any analytics SDKs that transmit personal data to third parties.

We may disclose information only in the following circumstances:

- **With your explicit prior consent**, or
- **As required by Korean law or law enforcement**, following legally prescribed procedures.

---

## 6. Data Processing Entrusted to Third Parties

To operate the service, we entrust certain data-processing tasks to the following sub-processors. All sub-processor agreements include prohibitions on processing data beyond the specified purpose, as required by PIPA Article 26.

| Sub-processor | Task | Data Entrusted | Duration |
|---|---|---|---|
| Google (Firebase Cloud Messaging) | Push notification delivery | FCM device token, notification content | Duration of service use |
| Google (Google Sign-In) | Social login authentication | OAuth access token | Duration of authentication |
| Kakao | Social login authentication | OAuth access token | Duration of authentication |
| Apple | Social login authentication + token revocation on withdrawal | OAuth access token | Duration of authentication |
| AWS (Amazon S3) | Storage of character and item image / animation files | Media files (no personally identifiable information) | Duration of service use |

---

## 7. Your Rights

Under PIPA, you have the following rights regarding your personal information:

1. **Right to Access** — request to view the personal information we hold about you (via in-app settings or email to {{이메일}}).
2. **Right to Rectification** — request correction of inaccurate information.
3. **Right to Suspension of Processing** — request restriction of processing.
4. **Right to Erasure / Account Withdrawal** — delete your account and all associated data immediately via in-app settings → "Withdraw Account" (hard delete).
5. **Password Change** — available for email accounts via in-app settings.
6. **Withdraw Notification Consent** — toggle push notification permissions in in-app settings at any time.

We will respond to rights requests without delay. Data will not be used or shared while a rectification or deletion request is being processed.

---

## 8. Security Measures

We implement the following technical and administrative safeguards under PIPA Article 29:

| Measure | Details |
|---|---|
| Password encryption | BCrypt one-way hash — plaintext is never stored or recoverable |
| Transport security | All communications use HTTPS (TLS) |
| Authentication | JWT-based access tokens (30-minute expiry) + refresh tokens (14-day expiry) |
| Access control | Principle of least privilege; personnel access limited to operational necessity |
| Social token security | Apple OAuth token revoked via Apple Server API upon account withdrawal |

---

## 9. Privacy Officer

The following individual is designated as our Personal Information Protection Officer under PIPA:

| Field | Details |
|---|---|
| Organization | {{운영자명}} |
| Representative | {{대표자명}} |
| Address | {{소재지}} |
| Privacy Officer | {{보호책임자명}} |
| Contact Email | {{이메일}} |

---

## 10. Remedies for Privacy Violations

If you are not satisfied with our response to a privacy concern, or wish to report a violation, you may contact the following Korean government authorities:

| Authority | Phone | Website |
|---|---|---|
| Personal Information Protection Commission (PIPC) | 1833-6972 | www.pipc.go.kr |
| Korea Internet & Security Agency (KISA) Privacy Infringement Report Center | 118 | privacy.kisa.or.kr |
| Supreme Prosecutors' Office, Cyber Investigation Division | 1301 | www.spo.go.kr |
| National Police Agency, Cyber Investigation Bureau | 182 | ecrm.cyber.go.kr |

---

## 11. Children Under 14

Doitdo does not knowingly collect information from users under the age of 14.

- Users must be **14 years of age or older** under Korea's PIPA (note: this is the Korean standard — 14, not 13 as in U.S. COPPA).
- If a user's date of birth entered during onboarding indicates they are under 14, **all of that user's data is immediately and permanently deleted** (hard delete), and the account is closed.
- We do not operate a parental-consent process for users under 14; access is blocked entirely.
- If we discover that information from a child under 14 has been collected, we will delete it immediately.

To report a concern: {{이메일}}

---

## 12. Changes to This Policy

1. This Privacy Policy is effective from **{{시행일}}** (version {{버전}}).
2. We will notify users of material changes via in-app notice or email at least **7 days** before the change takes effect (at least **30 days** for changes that are materially less favorable to users).
3. Previous versions of this policy are available upon request.

---

*{{운영자명}} Privacy Policy — Version {{버전}} — Effective {{시행일}}*

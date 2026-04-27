# App Access Instructions for App Store / Play Store Review

> Document type: App Review Access Instructions (English)
> App: Doitdo (`com.d107.doitdo`)
> Prepared for: Apple App Store Review & Google Play Store Review

---

<!-- Placeholder locations
- {{TEST_EMAIL}}    : Core Access section, Test Account Details table
- {{TEST_PASSWORD}} : Core Access section, Test Account Details table
-->

## Core Access Information

Doitdo can be accessed via email signup or social login (Google / Kakao / Apple).

**Test Account (pre-configured, ready to use):**

```
Email:    {{TEST_EMAIL}}
Password: {{TEST_PASSWORD}}
```

| Field | Value |
|---|---|
| Login method | Email + password |
| Onboarding status | Completed (birth date and terms already registered) |
| Two-factor authentication | None |
| QR code or biometrics | Not required |
| Age gate | Pre-cleared — test account birth date is set to bypass the under-14 restriction |

---

## Sign-Up and Onboarding Flow

For reviewers who wish to observe the full registration flow from scratch, the sequence is:

1. **Launch app** → tap "Sign Up" on the login screen.
2. **Enter credentials** — email address + password (or choose a social login provider).
3. **Birth date modal** — required step immediately after account creation. Users under 14 years of age are blocked at this step (see Age Policy section below).
4. **Terms agreement modal** — agree to Terms of Service (required), Privacy Policy (required), and marketing notifications (optional).
5. **Main screen** — onboarding complete; all features are accessible.

---

## Age Policy (Under-14 Block)

Doitdo enforces Korea's **Personal Information Protection Act (PIPA)** age threshold of **14 years old** (not the U.S. COPPA threshold of 13).

- If a user enters a date of birth that indicates they are under 14 during the onboarding birth-date step, the account and all associated data are **immediately and permanently deleted** (hard delete).
- No parental-consent flow is offered; access is blocked entirely.
- The provided test account has a birth date pre-set to a date that clears this restriction. Reviewers do not need to worry about triggering the under-14 block.

---

## Social Login Options

All three social login providers are fully integrated and available for review:

| Provider | Platform | Notes |
|---|---|---|
| Google Sign-In | Android + iOS | Standard OAuth 2.0 flow |
| Kakao Login | Android + iOS | Korean social login provider |
| Apple Sign-In | iOS only | Required by App Store guidelines; token revocation on account withdrawal is implemented |

**Note:** Each social login provider follows the same post-authentication onboarding flow (birth date → terms) as email signup.

---

## Push Notification Permission

- The app requests push-notification permission during or after onboarding (**optional**).
- If permission is granted, the user receives service notifications: TODO reminders, character growth events, and character farewell alerts.
- Notifications are **service-only** (no marketing push notifications are sent unless the user explicitly opts in during the terms step).
- Permission can be toggled at any time in the in-app Settings screen.

**For review purposes**, the notification permission prompt can be dismissed; it does not affect core functionality.

---

## Camera and Photo Library Permission

- The app requests camera and photo-library access only when the user navigates to set a Tamagotchi character's profile image (**optional**).
- This permission is never requested on launch.
- If declined, all other features remain fully functional; the character profile image defaults to a pre-set image.

**Access path for review:** Main screen → Character tab → Character profile → "Edit Profile Image."

---

## Account Withdrawal (Data Deletion)

The app provides a clearly accessible account-deletion flow that performs an **immediate hard delete** of all user data:

1. Settings screen → "Withdraw Account"
2. Confirm withdrawal
3. All data (account, TODOs, character, inventory, Doredits, FCM token) is permanently deleted from the database.
4. For Apple Sign-In accounts, the Apple OAuth token is **revoked via Apple's Server API** at the time of withdrawal, in compliance with **App Store Review Guideline 5.1.1(v)**.

---

## Apple Sign-In Compliance

In compliance with **App Store Review Guideline 5.1.1(v)**:

- Apple Sign-In is offered as a login option wherever other third-party social logins (Google, Kakao) are available.
- Upon account withdrawal by an Apple Sign-In user, the app calls the **Apple Server API `POST /auth/revoke`** to revoke the associated OAuth refresh token, ensuring the user's Apple ID is fully disassociated from Doitdo.
- The revocation is performed server-side (backend) and is transparent to the user.

---

## No Special Hardware or Features Required

| Feature | Required for Review? | Notes |
|---|---|---|
| NFC | No | Not used |
| Bluetooth | No | Not used |
| Location / GPS | No | Not requested or used |
| ARKit / AR features | No | Not used |
| In-app purchases | No | No real-money transactions; Doredits earned by TODO completion only |
| Subscription | No | Free app; no subscription model |

---

## Summary for Reviewer

- **Login:** Use the pre-configured test account above, or sign up with a new email.
- **All features accessible:** TODO management, Tamagotchi character, inventory, settings.
- **No age gate triggered** by the test account.
- **Apple Sign-In token revocation** is implemented server-side on account withdrawal.
- **No mandatory permissions** — camera and notifications are optional and can be declined without impacting core review.

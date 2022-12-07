# Signup flow

## initiate signup

- starts on _dashboard_ `/signup` route, sends an `initiateSignup` mutation with email and
  password
- _api_ responds to `initiateSignup` mutation by:
  - creating an `Admin` in the database with `.subscriptionStatus` set to
    `.pendingEmailVerification`
  - stores an ephemeral verification token
  - generates an email containing link to: `dash.gertrude.app/verify-signup-email/<token>`

## verify email

- When admin clicks link in email above, _dashboard_ sends a `verifyEmailMutation`
  containing just the token
- _api_ responds to `verifyEmailMutation` by:
  - resolving the token into an `Admin.Id` from ephemeral storage
  - setting `.subscriptionStatus` to `.emailVerified`
  - creating an `AdminVerifiedNotificationMethod` for their signup email
  - replies with the `Admin` resource (which the dashboard uses only the `id`)

## prepare and redirecto to stripe checkout

- when the _dashboard_ recieves the `Admin.Id` value back from email verification, it
  sends a `createSignupPaymentUrl` mutation, sending along the admin id
- the _api_ responds to this `createSignupPaymentUrl` mutation by creating a temporary
  checkout session with stripe, by calling the stripe API, and returning the session URL.
  It embeds the admin id into the stripe checkout session metadata, which is used later
- when the _dashboard_ gets the checkout URL, it redirects to it

## return from stripe checkout (happy path)

- when the user finishes the stripe checkout process successfully, they are redirected
  back to the dashboard at `/checkout-success` with a _checkout session id_ embedded in
  the query param
- from this _dashboard_ route, a `handleSignupPaymentSuccess` mutation is sent to the api,
  containing _only_ the checkout session id
- the _api_ responds to `handleSignupPaymentSuccess` by:
  - pulling the stripe session from the stripe API in order to get a `subscription`
    object, AND resolve the admin id stored as metadata (see above)
  - once it finds the admin id, and has the subscription, it queries the stripe API again,
    to get the current **status** of the subscription, and _updates the model in the
    database_ accordingly
  - finally, it returns an `AdminToken` as the mutation response (which the _dashboard_
    uses for auth and localStorage things)
- when the _dashboard_ gets a successful response from payment success, it:
  - the storage middleware listening for the action stores the admin id and token
  - the auth redux slice stores the admin credentials
  - the signup redux slice stores the successful checkout request state
  - and the user is redirected to the dashboard: `/`

## return from stripe checkout (sad, cancel path)

- similar to the success state, the _session id_ is used to send a cancel mutation to the
  API
- the _api_ resolves the admin from the subscription via the session (using same 2 stripe
  api calls as happy path)
- after finding the admin who canceled, it updates their status in the database, and
  returns a generic success



# STX-DIDForge - Decentralized Identity Management Contract

This Clarity smart contract provides a robust system for managing, verifying, and querying decentralized user identities on the **Stacks blockchain**. It enables users to register unique DIDs (Decentralized Identifiers), attach claims, and be verified by the contract owner.

---

## 🧾 Features

* ✅ Create and manage user identities with DIDs
* 🧩 Add and verify custom claims
* 🔐 Owner-authorized identity and claim verification
* 📈 Track total registered identities
* 🔍 Query identity and claim information

---

## 📚 Contract Overview

### Constants

| Name                     | Description                        |
| ------------------------ | ---------------------------------- |
| `CONTRACT-OWNER`         | Address that deployed the contract |
| `ERR-NOT-AUTHORIZED`     | Unauthorized access error          |
| `ERR-IDENTITY-EXISTS`    | Identity already exists            |
| `ERR-IDENTITY-NOT-FOUND` | Identity does not exist            |
| `ERR-INVALID-CLAIM`      | Claim is malformed                 |
| `ERR-INVALID-DID`        | DID is invalid or empty            |
| `ERR-INVALID-USER`       | User not found                     |
| `ERR-CLAIM-NOT-FOUND`    | Claim not found                    |

---

### Data Structures

#### `user-identities` *(map)*

Stores user identity data.

```clarity
principal => {
  did: string-ascii (max 100),
  verification-status: bool,
  claims: list of strings (max 10, each up to 200 chars),
  created-at: uint,
  updated-at: uint
}
```

#### `verified-claims` *(map)*

Tracks verification status of individual claims.

```clarity
{ user: principal, claim: string-ascii(200) } => bool
```

#### `identity-count` *(data-var)*

Tracks the number of identities created.

---

## ⚙️ Functions

### 🧑 Identity Management

* **`(create-identity (did))`**
  Creates a new identity with a given DID.

* **`(update-did (new-did))`**
  Updates the DID of the sender’s identity.

* **`(add-claim (claim))`**
  Adds a claim to the sender’s identity (max 10 claims per identity).

### 🛡️ Verification (Owner-only)

* **`(verify-claim (user claim))`**
  Marks a claim for a user as verified.

* **`(set-verification-status (user status))`**
  Sets the verification status of a user identity.

### 🔍 Read-only Functions

* **`(get-identity (user))`**
  Returns the full identity struct.

* **`(get-all-claims (user))`**
  Returns the list of claims associated with a user.

* **`(is-claim-verified (user claim))`**
  Returns `true` if the claim has been verified.

* **`(is-identity-verified (user))`**
  Checks if a user's identity is fully verified.

* **`(get-identity-count)`**
  Returns the total number of identities registered.

---

## 🚨 Access Control

* Only the **contract owner** (the deployer) can call:

  * `verify-claim`
  * `set-verification-status`

---

## 🔐 Identity Lifecycle

1. **User calls** `create-identity` with a valid DID.
2. **User may call** `add-claim` to submit personal or professional claims.
3. **Owner calls** `verify-claim` to validate specific claims.
4. **Owner calls** `set-verification-status` to mark the entire identity as verified.
5. Anyone can read identities and verification statuses using the read-only functions.

---

## 📦 Deployment Notes

* Must be deployed by the address intended to be `CONTRACT-OWNER`.
* Ensure `tx-sender` correctly represents the deploying entity.

---

## 🧪 Example Use Case

A decentralized university uses this contract to:

* Register students with a DID.
* Add claims like “Completed BSc in Computer Science”.
* Verify claims and identity status.
* Employers query the smart contract to validate academic records.

---


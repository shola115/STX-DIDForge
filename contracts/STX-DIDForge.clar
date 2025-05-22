;; STX-DIDForge
;; This contract provides functionality for creating, managing, and verifying user identities

;; Contract Owner
(define-constant CONTRACT-OWNER tx-sender)

;; Error Codes for Various Validation Scenarios
(define-constant ERR-NOT-AUTHORIZED (err u1))     ;; When a user lacks proper authorization
(define-constant ERR-IDENTITY-EXISTS (err u2))    ;; When trying to create an identity that already exists
(define-constant ERR-IDENTITY-NOT-FOUND (err u3)) ;; When attempting to access a non-existent identity
(define-constant ERR-INVALID-CLAIM (err u4))      ;; When a claim does not meet validation criteria
(define-constant ERR-INVALID-DID (err u5))        ;; When a Decentralized Identifier (DID) is invalid
(define-constant ERR-INVALID-USER (err u6))       ;; When a user is not valid
(define-constant ERR-CLAIM-NOT-FOUND (err u7))    ;; When a specific claim cannot be found

;; User Identities Map
;; Stores comprehensive information about each user's identity
(define-map user-identities 
  principal  ;; The unique blockchain address of the user
  {
    did: (string-ascii 100),           ;; Decentralized Identifier (max 100 characters)
    verification-status: bool,          ;; Whether the identity is verified
    claims: (list 10 (string-ascii 200)), ;; List of claims (max 10, each up to 200 characters)
    created-at: uint,                  ;; Block height when identity was created
    updated-at: uint                   ;; Block height of last update
  }
)

;; Verified Claims Map
;; Tracks which claims have been verified for specific users
(define-map verified-claims 
  { 
    user: principal,          ;; User's blockchain address
    claim: (string-ascii 200) ;; Specific claim (max 200 characters)
  } 
  bool  ;; Verification status of the claim
)

;; Tracks the total number of identities created
(define-data-var identity-count uint u0)

;; Creates a new user identity
;; @param did - Decentralized Identifier for the user
(define-public (create-identity (did (string-ascii 100)))
  (begin
    ;; Ensure no existing identity for this user
    (asserts! (is-none (map-get? user-identities tx-sender)) ERR-IDENTITY-EXISTS)

    ;; Validate DID: must not be empty and within length limit
    (asserts! (> (len did) u0) ERR-INVALID-DID)
    (asserts! (<= (len did) u100) ERR-INVALID-DID)

    ;; Create new identity entry
    (map-set user-identities 
      tx-sender 
      {
        did: did,
        verification-status: false,  ;; Initially unverified
        claims: (list ),              ;; No claims initially
        created-at: block-height,    ;; Current block height
        updated-at: block-height
      }
    )

    ;; Increment total identity count
    (var-set identity-count (+ (var-get identity-count) u1))
    (ok true)
  )
)

;; Updates the Decentralized Identifier (DID) for an existing identity
;; @param new-did - New DID to replace the existing one
(define-public (update-did (new-did (string-ascii 100)))
  (let 
    (
      ;; Retrieve current identity, fail if not found
      (current-identity (unwrap! (map-get? user-identities tx-sender) ERR-IDENTITY-NOT-FOUND))
    )
    ;; Validate new DID
    (asserts! (> (len new-did) u0) ERR-INVALID-DID)
    (asserts! (<= (len new-did) u100) ERR-INVALID-DID)

    ;; Update identity with new DID
    (map-set user-identities 
      tx-sender 
      (merge current-identity 
        { 
          did: new-did,
          updated-at: block-height 
        }
      )
    )
    (ok true)
  )
)

;; Adds a new claim to a user's identity
;; @param claim - Claim to be added to the identity
(define-public (add-claim (claim (string-ascii 200)))
  (let 
    (
      ;; Retrieve current identity, fail if not found
      (current-identity (unwrap! (map-get? user-identities tx-sender) ERR-IDENTITY-NOT-FOUND))
    )
    ;; Validate claim
    (asserts! (> (len claim) u0) ERR-INVALID-CLAIM)
    (asserts! (<= (len claim) u200) ERR-INVALID-CLAIM)

    (let
      (
        ;; Manage claims list: add if under 10 claims, otherwise keep existing
        (updated-claims 
          (if (< (len (get claims current-identity)) u10)
            (unwrap-panic (as-max-len? (append (get claims current-identity) claim) u10))
            (get claims current-identity)
          )
        )
      )
      ;; Update identity with new claims list
      (map-set user-identities 
        tx-sender 
        (merge current-identity 
          { 
            claims: updated-claims,
            updated-at: block-height 
          }
        )
      )
      (ok true)
    )
  )
)


;; Retrieves all claims for a specific user
;; @param user - User's blockchain address
;; @returns List of claims or an error if identity not found
(define-read-only (get-all-claims (user principal))
  (match (map-get? user-identities user)
    identity (ok (get claims identity))
    (err ERR-IDENTITY-NOT-FOUND)
  )
)

;; Checks if a user's entire identity is verified
;; @param user - User's blockchain address
;; @returns Boolean verification status or error
(define-read-only (is-identity-verified (user principal))
  (match (map-get? user-identities user)
    identity (ok (get verification-status identity))
    (err ERR-IDENTITY-NOT-FOUND)
  )
)

;; Returns the total number of identities created in this contract
;; @returns Total identity count
(define-read-only (get-identity-count)
  (ok (var-get identity-count))
)
;; Verifies a specific claim for a user (only callable by contract owner)
;; @param user - User's blockchain address
;; @param claim - Specific claim to verify
(define-public (verify-claim (user principal) (claim (string-ascii 200)))
  (begin
    ;; Ensure only contract owner can verify claims
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Validate user and claim
    (asserts! (is-some (map-get? user-identities user)) ERR-INVALID-USER)
    (asserts! (> (len claim) u0) ERR-INVALID-CLAIM)
    (asserts! (<= (len claim) u200) ERR-INVALID-CLAIM)

    ;; Mark claim as verified
    (map-set verified-claims 
      { user: user, claim: claim } 
      true
    )
    (ok true)
  )
)

;; Sets the overall verification status for a user (only callable by contract owner)
;; @param user - User's blockchain address
;; @param status - Verification status to set
(define-public (set-verification-status (user principal) (status bool))
  (begin
    ;; Ensure only contract owner can set verification status
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Validate user exists
    (asserts! (is-some (map-get? user-identities user)) ERR-INVALID-USER)

    (let
      (
        ;; Retrieve current identity
        (current-identity (unwrap-panic (map-get? user-identities user)))
      )
      ;; Update verification status
      (map-set user-identities 
        user 
        (merge current-identity 
          { 
            verification-status: status,
            updated-at: block-height 
          }
        )
      )
      (ok true)
    )
  )
)

;; Checks if a specific claim is verified for a user
;; @param user - User's blockchain address
;; @param claim - Specific claim to check
;; @returns Boolean indicating claim verification status
(define-read-only (is-claim-verified (user principal) (claim (string-ascii 200)))
  (default-to false 
    (map-get? verified-claims { user: user, claim: claim })
  )
)

;; Retrieves the full identity information for a user
;; @param user - User's blockchain address
;; @returns Optional identity information
(define-read-only (get-identity (user principal))
  (map-get? user-identities user)
)

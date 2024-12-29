;; QuantumVault - Secure Decentralized Escrow
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-EXISTS (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-NOT-FOUND (err u103))
(define-constant ERR-WRONG-STATUS (err u104))
(define-constant ERR-EXPIRED (err u105))

;; Escrow status enum
(define-data-var status-map (list 5 (string-ascii 20)) (list "PENDING" "FUNDED" "COMPLETED" "CANCELLED" "DISPUTED"))

;; Escrow agreement structure
(define-map escrows
    { id: uint }
    {
        seller: principal,
        buyer: principal,
        amount: uint,
        status: uint,
        expiry: uint,
        created-at: uint
    }
)

;; Track next escrow ID
(define-data-var next-escrow-id uint u1)

;; Create new escrow agreement
(define-public (create-escrow (seller principal) (amount uint) (expiry uint))
    (let
        (
            (escrow-id (var-get next-escrow-id))
            (current-time block-height)
        )
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (> expiry current-time) ERR-INVALID-AMOUNT)
        (try! (map-insert escrows
            { id: escrow-id }
            {
                seller: seller,
                buyer: tx-sender,
                amount: amount,
                status: u0,
                expiry: expiry,
                created-at: current-time
            }
        ))
        (var-set next-escrow-id (+ escrow-id u1))
        (ok escrow-id)
    )
)

;; Fund escrow
(define-public (fund-escrow (escrow-id uint))
    (let
        ((escrow (unwrap! (map-get? escrows {id: escrow-id}) ERR-NOT-FOUND)))
        (asserts! (is-eq (get status escrow) u0) ERR-WRONG-STATUS)
        (asserts! (is-eq tx-sender (get buyer escrow)) ERR-NOT-AUTHORIZED)
        (try! (stx-transfer? (get amount escrow) tx-sender (as-contract tx-sender)))
        (map-set escrows
            {id: escrow-id}
            (merge escrow {status: u1})
        )
        (ok true)
    )
)

;; Release funds to seller
(define-public (release-escrow (escrow-id uint))
    (let
        ((escrow (unwrap! (map-get? escrows {id: escrow-id}) ERR-NOT-FOUND)))
        (asserts! (is-eq (get status escrow) u1) ERR-WRONG-STATUS)
        (asserts! (is-eq tx-sender (get buyer escrow)) ERR-NOT-AUTHORIZED)
        (as-contract
            (try! (stx-transfer? (get amount escrow) tx-sender (get seller escrow)))
        )
        (map-set escrows
            {id: escrow-id}
            (merge escrow {status: u2})
        )
        (ok true)
    )
)

;; Cancel escrow (requires both parties consent)
(define-public (cancel-escrow (escrow-id uint))
    (let
        ((escrow (unwrap! (map-get? escrows {id: escrow-id}) ERR-NOT-FOUND)))
        (asserts! (is-eq (get status escrow) u1) ERR-WRONG-STATUS)
        (asserts! (or
            (is-eq tx-sender (get buyer escrow))
            (is-eq tx-sender (get seller escrow))
        ) ERR-NOT-AUTHORIZED)
        (as-contract
            (try! (stx-transfer? (get amount escrow) tx-sender (get buyer escrow)))
        )
        (map-set escrows
            {id: escrow-id}
            (merge escrow {status: u3})
        )
        (ok true)
    )
)

;; Raise dispute
(define-public (raise-dispute (escrow-id uint))
    (let
        ((escrow (unwrap! (map-get? escrows {id: escrow-id}) ERR-NOT-FOUND)))
        (asserts! (is-eq (get status escrow) u1) ERR-WRONG-STATUS)
        (asserts! (or
            (is-eq tx-sender (get buyer escrow))
            (is-eq tx-sender (get seller escrow))
        ) ERR-NOT-AUTHORIZED)
        (map-set escrows
            {id: escrow-id}
            (merge escrow {status: u4})
        )
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-escrow (escrow-id uint))
    (map-get? escrows {id: escrow-id})
)

(define-read-only (get-status-string (status-id uint))
    (element-at (var-get status-map) status-id)
)
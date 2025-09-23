(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ALREADY_EXISTS (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_AMOUNT (err u103))
(define-constant ERR_INSUFFICIENT_BALANCE (err u104))
(define-constant ERR_WORK_NOT_COMPLETED (err u105))
(define-constant ERR_WORK_ALREADY_COMPLETED (err u106))
(define-constant ERR_DISPUTE_EXISTS (err u107))
(define-constant ERR_INVALID_STATUS (err u108))

(define-constant CONTRACT_OWNER tx-sender)
(define-constant INSURANCE_RATE u5)
(define-constant PLATFORM_FEE_RATE u2)

(define-data-var next-work-id uint u1)
(define-data-var total-insurance-fund uint u0)

(define-map workers
    { worker: principal }
    {
        reputation-score: uint,
        total-earnings: uint,
        completed-jobs: uint,
        insurance-contributions: uint,
        is-active: bool
    }
)

(define-map clients
    { client: principal }
    {
        total-spent: uint,
        active-contracts: uint,
        reputation-score: uint,
        is-verified: bool
    }
)

(define-map work-contracts
    { work-id: uint }
    {
        client: principal,
        worker: principal,
        amount: uint,
        description: (string-ascii 500),
        status: (string-ascii 20),
        created-at: uint,
        completed-at: (optional uint),
        insurance-amount: uint,
        platform-fee: uint
    }
)

(define-map escrow-balances
    { work-id: uint }
    { amount: uint }
)

(define-map disputes
    { work-id: uint }
    {
        raised-by: principal,
        reason: (string-ascii 500),
        status: (string-ascii 20),
        created-at: uint
    }
)

(define-map insurance-claims
    { work-id: uint }
    {
        claimant: principal,
        amount: uint,
        reason: (string-ascii 500),
        status: (string-ascii 20),
        approved-at: (optional uint)
    }
)

(define-public (register-worker)
    (let
        (
            (worker-data (map-get? workers { worker: tx-sender }))
        )
        (asserts! (is-none worker-data) ERR_ALREADY_EXISTS)
        (map-set workers
            { worker: tx-sender }
            {
                reputation-score: u50,
                total-earnings: u0,
                completed-jobs: u0,
                insurance-contributions: u0,
                is-active: true
            }
        )
        (ok true)
    )
)

(define-public (register-client)
    (let
        (
            (client-data (map-get? clients { client: tx-sender }))
        )
        (asserts! (is-none client-data) ERR_ALREADY_EXISTS)
        (map-set clients
            { client: tx-sender }
            {
                total-spent: u0,
                active-contracts: u0,
                reputation-score: u50,
                is-verified: false
            }
        )
        (ok true)
    )
)

(define-public (toggle-worker-status)
    (let
        (
            (worker-data (unwrap! (map-get? workers { worker: tx-sender }) ERR_NOT_FOUND))
        )
        (map-set workers
            { worker: tx-sender }
            (merge worker-data { is-active: (not (get is-active worker-data)) })
        )
        (ok true)
    )
)

(define-public (create-work-contract (worker principal) (amount uint) (description (string-ascii 500)))
    (let
        (
            (work-id (var-get next-work-id))
            (insurance-amount (/ (* amount INSURANCE_RATE) u100))
            (platform-fee (/ (* amount PLATFORM_FEE_RATE) u100))
            (total-required (+ amount (+ insurance-amount platform-fee)))
            (worker-data (unwrap! (map-get? workers { worker: worker }) ERR_NOT_FOUND))
            (client-data (unwrap! (map-get? clients { client: tx-sender }) ERR_NOT_FOUND))
        )
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (get is-active worker-data) ERR_NOT_AUTHORIZED)
        (try! (stx-transfer? total-required tx-sender (as-contract tx-sender)))
        (map-set work-contracts
            { work-id: work-id }
            {
                client: tx-sender,
                worker: worker,
                amount: amount,
                description: description,
                status: "active",
                created-at: stacks-block-height,
                completed-at: none,
                insurance-amount: insurance-amount,
                platform-fee: platform-fee
            }
        )
        (map-set escrow-balances
            { work-id: work-id }
            { amount: total-required }
        )
        (map-set clients
            { client: tx-sender }
            (merge client-data { active-contracts: (+ (get active-contracts client-data) u1) })
        )
        (var-set next-work-id (+ work-id u1))
        (var-set total-insurance-fund (+ (var-get total-insurance-fund) insurance-amount))
        (ok work-id)
    )
)

(define-public (complete-work (work-id uint))
    (let
        (
            (contract-data (unwrap! (map-get? work-contracts { work-id: work-id }) ERR_NOT_FOUND))
            (escrow-data (unwrap! (map-get? escrow-balances { work-id: work-id }) ERR_NOT_FOUND))
            (worker-data (unwrap! (map-get? workers { worker: (get worker contract-data) }) ERR_NOT_FOUND))
            (client-data (unwrap! (map-get? clients { client: (get client contract-data) }) ERR_NOT_FOUND))
        )
        (asserts! (is-eq tx-sender (get worker contract-data)) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq (get status contract-data) "active") ERR_WORK_ALREADY_COMPLETED)
        (map-set work-contracts
            { work-id: work-id }
            (merge contract-data {
                status: "completed",
                completed-at: (some stacks-block-height)
            })
        )
        (try! (as-contract (stx-transfer? (get amount contract-data) tx-sender (get worker contract-data))))
        (try! (as-contract (stx-transfer? (get platform-fee contract-data) tx-sender CONTRACT_OWNER)))
        (map-set workers
            { worker: (get worker contract-data) }
            (merge worker-data {
                total-earnings: (+ (get total-earnings worker-data) (get amount contract-data)),
                completed-jobs: (+ (get completed-jobs worker-data) u1),
                insurance-contributions: (+ (get insurance-contributions worker-data) (get insurance-amount contract-data)),
                reputation-score: (if (> (+ (get reputation-score worker-data) u2) u100) u100 (+ (get reputation-score worker-data) u2))
            })
        )
        (map-set clients
            { client: (get client contract-data) }
            (merge client-data {
                total-spent: (+ (get total-spent client-data) (get amount contract-data)),
                active-contracts: (- (get active-contracts client-data) u1),
                reputation-score: (if (> (+ (get reputation-score client-data) u1) u100) u100 (+ (get reputation-score client-data) u1))
            })
        )
        (map-delete escrow-balances { work-id: work-id })
        (ok true)
    )
)

(define-public (approve-work (work-id uint))
    (let
        (
            (contract-data (unwrap! (map-get? work-contracts { work-id: work-id }) ERR_NOT_FOUND))
        )
        (asserts! (is-eq tx-sender (get client contract-data)) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq (get status contract-data) "completed") ERR_WORK_NOT_COMPLETED)
        (map-set work-contracts
            { work-id: work-id }
            (merge contract-data { status: "approved" })
        )
        (ok true)
    )
)

(define-public (raise-dispute (work-id uint) (reason (string-ascii 500)))
    (let
        (
            (contract-data (unwrap! (map-get? work-contracts { work-id: work-id }) ERR_NOT_FOUND))
            (existing-dispute (map-get? disputes { work-id: work-id }))
        )
        (asserts! (is-none existing-dispute) ERR_DISPUTE_EXISTS)
        (asserts! (or (is-eq tx-sender (get client contract-data)) (is-eq tx-sender (get worker contract-data))) ERR_NOT_AUTHORIZED)
        (asserts! (not (is-eq (get status contract-data) "disputed")) ERR_INVALID_STATUS)
        (map-set disputes
            { work-id: work-id }
            {
                raised-by: tx-sender,
                reason: reason,
                status: "pending",
                created-at: stacks-block-height
            }
        )
        (map-set work-contracts
            { work-id: work-id }
            (merge contract-data { status: "disputed" })
        )
        (ok true)
    )
)

(define-public (resolve-dispute (work-id uint) (in-favor-of-worker bool))
    (let
        (
            (contract-data (unwrap! (map-get? work-contracts { work-id: work-id }) ERR_NOT_FOUND))
            (dispute-data (unwrap! (map-get? disputes { work-id: work-id }) ERR_NOT_FOUND))
            (escrow-data (unwrap! (map-get? escrow-balances { work-id: work-id }) ERR_NOT_FOUND))
        )
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq (get status dispute-data) "pending") ERR_INVALID_STATUS)
        (if in-favor-of-worker
            (try! (as-contract (stx-transfer? (get amount contract-data) tx-sender (get worker contract-data))))
            (try! (as-contract (stx-transfer? (get amount contract-data) tx-sender (get client contract-data))))
        )
        (try! (as-contract (stx-transfer? (get platform-fee contract-data) tx-sender CONTRACT_OWNER)))
        (map-set disputes
            { work-id: work-id }
            (merge dispute-data { status: "resolved" })
        )
        (map-set work-contracts
            { work-id: work-id }
            (merge contract-data { status: "resolved" })
        )
        (map-delete escrow-balances { work-id: work-id })
        (ok true)
    )
)

(define-public (claim-insurance (work-id uint) (reason (string-ascii 500)))
    (let
        (
            (contract-data (unwrap! (map-get? work-contracts { work-id: work-id }) ERR_NOT_FOUND))
            (existing-claim (map-get? insurance-claims { work-id: work-id }))
        )
        (asserts! (is-none existing-claim) ERR_ALREADY_EXISTS)
        (asserts! (is-eq tx-sender (get worker contract-data)) ERR_NOT_AUTHORIZED)
        (asserts! (or (is-eq (get status contract-data) "disputed") (is-eq (get status contract-data) "resolved")) ERR_INVALID_STATUS)
        (map-set insurance-claims
            { work-id: work-id }
            {
                claimant: tx-sender,
                amount: (get insurance-amount contract-data),
                reason: reason,
                status: "pending",
                approved-at: none
            }
        )
        (ok true)
    )
)

(define-public (approve-insurance-claim (work-id uint))
    (let
        (
            (claim-data (unwrap! (map-get? insurance-claims { work-id: work-id }) ERR_NOT_FOUND))
            (contract-data (unwrap! (map-get? work-contracts { work-id: work-id }) ERR_NOT_FOUND))
        )
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq (get status claim-data) "pending") ERR_INVALID_STATUS)
        (asserts! (>= (var-get total-insurance-fund) (get amount claim-data)) ERR_INSUFFICIENT_BALANCE)
        (try! (as-contract (stx-transfer? (get amount claim-data) tx-sender (get claimant claim-data))))
        (map-set insurance-claims
            { work-id: work-id }
            (merge claim-data {
                status: "approved",
                approved-at: (some stacks-block-height)
            })
        )
        (var-set total-insurance-fund (- (var-get total-insurance-fund) (get amount claim-data)))
        (ok true)
    )
)

(define-read-only (get-worker-profile (worker principal))
    (map-get? workers { worker: worker })
)

(define-read-only (get-client-profile (client principal))
    (map-get? clients { client: client })
)

(define-read-only (get-work-contract (work-id uint))
    (map-get? work-contracts { work-id: work-id })
)

(define-read-only (get-escrow-balance (work-id uint))
    (map-get? escrow-balances { work-id: work-id })
)

(define-read-only (get-dispute (work-id uint))
    (map-get? disputes { work-id: work-id })
)

(define-read-only (get-insurance-claim (work-id uint))
    (map-get? insurance-claims { work-id: work-id })
)

(define-read-only (get-insurance-fund-balance)
    (var-get total-insurance-fund)
)

(define-read-only (get-next-work-id)
    (var-get next-work-id)
)

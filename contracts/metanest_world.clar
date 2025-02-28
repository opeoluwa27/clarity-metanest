;; MetaNest World Contract
;; Manages virtual world creation and connections

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-world-owner (err u101))
(define-constant err-invalid-world (err u102))
(define-constant err-portal-exists (err u103))
(define-constant err-invalid-activity (err u104))
(define-constant err-insufficient-rewards (err u105))
(define-constant err-contract-paused (err u106))
(define-constant err-activity-cooldown (err u107))

;; Contract State
(define-data-var contract-paused bool false)
(define-data-var last-world-id uint u0)
(define-data-var activity-cooldown uint u100)

;; Define NFT for world ownership
(define-non-fungible-token metaworld-nft (string-ascii 64))

;; Define SFT for portal access
(define-fungible-token portal-token)

;; Define fungible token for rewards
(define-fungible-token world-rewards)

;; Data Maps
(define-map worlds
    { world-id: uint }
    {
        name: (string-ascii 64),
        owner: principal,
        description: (string-ascii 256),
        created-at: uint,
        activity-count: uint,
        total-rewards: uint,
        active: bool
    }
)

(define-map portals
    { from-world: uint, to-world: uint }
    {
        active: bool,
        access-token: uint,
        created-by: principal,
        expires-at: uint
    }
)

(define-map world-activities
    { world-id: uint, activity-id: uint }
    {
        name: (string-ascii 64),
        description: (string-ascii 256),
        reward-amount: uint,
        participants: uint,
        active: bool,
        last-participation: uint
    }
)

;; Admin Functions
(define-public (set-contract-pause (paused bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set contract-paused paused))
    )
)

(define-public (set-activity-cooldown (blocks uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set activity-cooldown blocks))
    )
)

;; Create new world
(define-public (create-world (name (string-ascii 64)) (description (string-ascii 256)))
    (begin
        (asserts! (not (var-get contract-paused)) err-contract-paused)
        (let
            (
                (world-id (+ (var-get last-world-id) u1))
                (world-nft-id (concat (to-string world-id) "-world"))
            )
            (try! (nft-mint? metaworld-nft world-nft-id tx-sender))
            (var-set last-world-id world-id)
            (map-set worlds
                { world-id: world-id }
                {
                    name: name,
                    owner: tx-sender,
                    description: description,
                    created-at: block-height,
                    activity-count: u0,
                    total-rewards: u0,
                    active: true
                }
            )
            (ok world-id)
        )
    )
)

;; Create activity in world
(define-public (create-activity (world-id uint) (name (string-ascii 64)) (description (string-ascii 256)) (reward-amount uint))
    (begin
        (asserts! (not (var-get contract-paused)) err-contract-paused)
        (let
            (
                (world-data (unwrap! (get-world-data world-id) err-invalid-world))
                (activity-id (+ (get activity-count world-data) u1))
            )
            (asserts! (is-eq (get owner world-data) tx-sender) err-not-world-owner)
            (asserts! (get active world-data) err-invalid-world)
            (try! (ft-mint? world-rewards reward-amount tx-sender))
            
            (map-set world-activities
                { world-id: world-id, activity-id: activity-id }
                {
                    name: name,
                    description: description,
                    reward-amount: reward-amount,
                    participants: u0,
                    active: true,
                    last-participation: u0
                }
            )
            (map-set worlds
                { world-id: world-id }
                (merge world-data {
                    activity-count: activity-id,
                    total-rewards: (+ (get total-rewards world-data) reward-amount)
                })
            )
            (ok activity-id)
        )
    )
)

[... remaining functions with similar improvements ...]

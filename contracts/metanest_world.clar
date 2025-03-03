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
(define-constant err-max-supply-reached (err u108))
(define-constant err-duplicate-name (err u109))

;; Contract State
(define-data-var contract-paused bool false)
(define-data-var last-world-id uint u0)
(define-data-var activity-cooldown uint u100)
(define-data-var max-reward-supply uint u1000000000)
(define-data-var current-reward-supply uint u0)

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

(define-map world-names
    { name: (string-ascii 64) }
    { world-id: uint }
)

(define-map user-activity-cooldowns
    { user: principal, activity-id: uint }
    { last-participation: uint }
)

;; New function: Transfer world ownership
(define-public (transfer-world-ownership (world-id uint) (new-owner principal))
    (let
        ((world-data (unwrap! (get-world-data world-id) err-invalid-world))
         (world-nft-id (concat (to-string world-id) "-world")))
        (begin
            (asserts! (is-eq tx-sender (get owner world-data)) err-not-world-owner)
            (try! (nft-transfer? metaworld-nft world-nft-id tx-sender new-owner))
            (map-set worlds
                { world-id: world-id }
                (merge world-data { owner: new-owner })
            )
            (ok true)
        )
    )
)

;; Modified create-activity function with supply management
(define-public (create-activity (world-id uint) (name (string-ascii 64)) (description (string-ascii 256)) (reward-amount uint))
    (begin
        (asserts! (not (var-get contract-paused)) err-contract-paused)
        (let
            (
                (world-data (unwrap! (get-world-data world-id) err-invalid-world))
                (activity-id (+ (get activity-count world-data) u1))
                (new-supply (+ (var-get current-reward-supply) reward-amount))
            )
            (asserts! (is-eq (get owner world-data) tx-sender) err-not-world-owner)
            (asserts! (get active world-data) err-invalid-world)
            (asserts! (<= new-supply (var-get max-reward-supply)) err-max-supply-reached)
            
            (try! (ft-mint? world-rewards reward-amount tx-sender))
            (var-set current-reward-supply new-supply)
            
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

[... remaining functions updated with similar improvements ...]

;; MetaNest World Contract
;; Manages virtual world creation and connections

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-world-owner (err u101))
(define-constant err-invalid-world (err u102))
(define-constant err-portal-exists (err u103))

;; Define NFT for world ownership
(define-non-fungible-token metaworld-nft (string-ascii 64))

;; Define SFT for portal access
(define-fungible-token portal-token)

;; Data Maps
(define-map worlds
    { world-id: uint }
    {
        name: (string-ascii 64),
        owner: principal,
        description: (string-ascii 256),
        created-at: uint
    }
)

(define-map portals
    { from-world: uint, to-world: uint }
    {
        active: bool,
        access-token: uint,
        created-by: principal
    }
)

;; Create new world
(define-public (create-world (name (string-ascii 64)) (description (string-ascii 256)))
    (let
        (
            (world-id (+ (default-to u0 (get-last-world-id)) u1))
            (world-nft-id (concat (to-string world-id) "-world"))
        )
        (try! (nft-mint? metaworld-nft world-nft-id tx-sender))
        (map-set worlds
            { world-id: world-id }
            {
                name: name,
                owner: tx-sender,
                description: description,
                created-at: block-height
            }
        )
        (ok world-id)
    )
)

;; Create portal between worlds
(define-public (create-portal (from-world uint) (to-world uint))
    (let
        (
            (from-world-data (unwrap! (get-world-data from-world) err-invalid-world))
            (to-world-data (unwrap! (get-world-data to-world) err-invalid-world))
        )
        (asserts! (is-eq (get owner from-world-data) tx-sender) err-not-world-owner)
        (asserts! (is-none (get-portal-data from-world to-world)) err-portal-exists)
        
        (let
            (
                (portal-token-id (generate-portal-token))
            )
            (try! (ft-mint? portal-token u1 tx-sender))
            (map-set portals
                { from-world: from-world, to-world: to-world }
                {
                    active: true,
                    access-token: portal-token-id,
                    created-by: tx-sender
                }
            )
            (ok portal-token-id)
        )
    )
)

;; Get world data
(define-read-only (get-world-data (world-id uint))
    (map-get? worlds { world-id: world-id })
)

;; Get portal data
(define-read-only (get-portal-data (from-world uint) (to-world uint))
    (map-get? portals { from-world: from-world, to-world: to-world })
)

;; Helper functions
(define-data-var last-world-id uint u0)

(define-private (get-last-world-id)
    (ok (var-get last-world-id))
)

(define-private (generate-portal-token)
    (let
        (
            (token-id (+ (unwrap! (get-last-world-id) err-invalid-world) u1000))
        )
        token-id
    )
)

;; Check world ownership
(define-private (is-world-owner (world-id uint) (address principal))
    (let
        (
            (world-data (unwrap! (get-world-data world-id) err-invalid-world))
        )
        (is-eq (get owner world-data) address)
    )
)
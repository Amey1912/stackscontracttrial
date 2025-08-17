;; Token Generator and Swap Contract
;; This contract allows users to generate tokens and swap them securely

;; Define the contract owner
(define-constant contract-owner tx-sender)

;; Error constants
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-swap-not-found (err u104))
(define-constant err-swap-expired (err u105))
(define-constant err-swap-already-executed (err u106))
(define-constant err-invalid-swap-id (err u107))

;; Token constants
(define-constant token-name "GeneratedToken")
(define-constant token-symbol "GEN")
(define-constant token-decimals u6)

;; Generation parameters
(define-data-var generation-rate uint u1000) ;; tokens per generation
(define-data-var generation-cost uint u1000000) ;; microSTX cost to generate
(define-data-var max-supply uint u1000000000000) ;; maximum total supply

;; Token state
(define-data-var total-supply uint u0)
(define-map token-balances principal uint)
(define-map allowed { owner: principal, spender: principal } uint)

;; Swap state
(define-data-var next-swap-id uint u1)
(define-map swaps
  uint
  {
    creator: principal,
    token-amount: uint,
    stx-amount: uint,
    counterparty: (optional principal),
    expiry: uint,
    executed: bool
  }
)

;; Generation tracking
(define-map user-generation-count principal uint)
(define-map last-generation-block principal uint)
(define-data-var min-blocks-between-generation uint u144) ;; ~1 day

;; Token functions

;; Get token balance
(define-read-only (get-balance (who principal))
  (default-to u0 (map-get? token-balances who))
)

;; Get total supply
(define-read-only (get-total-supply)
  (var-get total-supply)
)

;; Get token info
(define-read-only (get-token-info)
  {
    name: token-name,
    symbol: token-symbol,
    decimals: token-decimals,
    total-supply: (var-get total-supply)
  }
)

;; Internal function to set balance
(define-private (set-balance (who principal) (new-balance uint))
  (map-set token-balances who new-balance)
)

;; Internal function to get allowance
(define-read-only (get-allowance (owner principal) (spender principal))
  (default-to u0 (map-get? allowed { owner: owner, spender: spender }))
)

;; Transfer tokens
(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (let ((sender-balance (get-balance sender)))
    (asserts! (>= sender-balance amount) err-insufficient-balance)
    (asserts! (> amount u0) err-invalid-amount)
    (set-balance sender (- sender-balance amount))
    (set-balance recipient (+ (get-balance recipient) amount))
    (print { 
      action: "transfer", 
      sender: sender, 
      recipient: recipient, 
      amount: amount,
      memo: memo 
    })
    (ok true)
  )
)

;; Generate tokens by paying STX
(define-public (generate-tokens)
  (let 
    (
      (sender tx-sender)
      (current-block stacks-block-height)
      (last-gen-block (default-to u0 (map-get? last-generation-block sender)))
      (generation-amount (var-get generation-rate))
      (cost (var-get generation-cost))
      (current-supply (var-get total-supply))
      (new-supply (+ current-supply generation-amount))
    )
    ;; Check rate limiting
    (asserts! (>= (- current-block last-gen-block) (var-get min-blocks-between-generation)) 
              (err u108)) ;; too soon to generate again
    
    ;; Check max supply
    (asserts! (<= new-supply (var-get max-supply)) (err u109)) ;; would exceed max supply
    
    ;; Transfer STX cost from sender to contract
    (try! (stx-transfer? cost sender (as-contract tx-sender)))
    
    ;; Mint tokens to sender
    (set-balance sender (+ (get-balance sender) generation-amount))
    (var-set total-supply new-supply)
    
    ;; Update generation tracking
    (map-set last-generation-block sender current-block)
    (map-set user-generation-count sender 
             (+ (default-to u0 (map-get? user-generation-count sender)) u1))
    
    (print {
      action: "generate-tokens",
      generator: sender,
      amount: generation-amount,
      cost: cost,
      block: current-block
    })
    
    (ok generation-amount)
  )
)

;; Create a swap offer
(define-public (create-swap (token-amount uint) (stx-amount uint) (counterparty (optional principal)) (duration uint))
  (let 
    (
      (swap-id (var-get next-swap-id))
      (sender tx-sender)
      (expiry (+ stacks-block-height duration))
    )
    (asserts! (> token-amount u0) err-invalid-amount)
    (asserts! (> stx-amount u0) err-invalid-amount)
    (asserts! (>= (get-balance sender) token-amount) err-insufficient-balance)
    (asserts! (> duration u0) err-invalid-amount)
    
    ;; Lock the tokens by transferring to contract
    (try! (transfer token-amount sender (as-contract tx-sender) none))
    
    ;; Create swap record
    (map-set swaps swap-id {
      creator: sender,
      token-amount: token-amount,
      stx-amount: stx-amount,
      counterparty: counterparty,
      expiry: expiry,
      executed: false
    })
    
    ;; Increment swap ID
    (var-set next-swap-id (+ swap-id u1))
    
    (print {
      action: "create-swap",
      swap-id: swap-id,
      creator: sender,
      token-amount: token-amount,
      stx-amount: stx-amount,
      counterparty: counterparty,
      expiry: expiry
    })
    
    (ok swap-id)
  )
)

;; Execute a swap
(define-public (execute-swap (swap-id uint))
  (let 
    (
      (swap-data (unwrap! (map-get? swaps swap-id) err-swap-not-found))
      (sender tx-sender)
    )
    ;; Verify swap conditions
    (asserts! (not (get executed swap-data)) err-swap-already-executed)
    (asserts! (< stacks-block-height (get expiry swap-data)) err-swap-expired)
    (asserts! (or (is-none (get counterparty swap-data))
                  (is-eq (some sender) (get counterparty swap-data))) err-unauthorized)
    
    ;; Transfer STX from executor to swap creator
    (try! (stx-transfer? (get stx-amount swap-data) sender (get creator swap-data)))
    
    ;; Transfer tokens from contract to executor
    (try! (as-contract (transfer (get token-amount swap-data) 
                                (as-contract tx-sender) 
                                sender 
                                none)))
    
    ;; Mark swap as executed
    (map-set swaps swap-id (merge swap-data { executed: true }))
    
    (print {
      action: "execute-swap",
      swap-id: swap-id,
      executor: sender,
      creator: (get creator swap-data),
      token-amount: (get token-amount swap-data),
      stx-amount: (get stx-amount swap-data)
    })
    
    (ok true)
  )
)

;; Cancel a swap (only creator can cancel)
(define-public (cancel-swap (swap-id uint))
  (let 
    (
      (swap-data (unwrap! (map-get? swaps swap-id) err-swap-not-found))
      (sender tx-sender)
    )
    (asserts! (is-eq sender (get creator swap-data)) err-unauthorized)
    (asserts! (not (get executed swap-data)) err-swap-already-executed)
    
    ;; Return tokens to creator
    (try! (as-contract (transfer (get token-amount swap-data) 
                                (as-contract tx-sender) 
                                sender 
                                none)))
    
    ;; Mark swap as executed (cancelled)
    (map-set swaps swap-id (merge swap-data { executed: true }))
    
    (print {
      action: "cancel-swap",
      swap-id: swap-id,
      creator: sender
    })
    
    (ok true)
  )
)

;; Get swap details
(define-read-only (get-swap (swap-id uint))
  (map-get? swaps swap-id)
)

;; Get user generation stats
(define-read-only (get-generation-stats (user principal))
  {
    generation-count: (default-to u0 (map-get? user-generation-count user)),
    last-generation-block: (default-to u0 (map-get? last-generation-block user)),
    can-generate-at-block: (+ (default-to u0 (map-get? last-generation-block user)) 
                             (var-get min-blocks-between-generation))
  }
)

;; Admin functions (only contract owner)

;; Update generation parameters
(define-public (set-generation-params (rate uint) (cost uint) (min-blocks uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set generation-rate rate)
    (var-set generation-cost cost)
    (var-set min-blocks-between-generation min-blocks)
    (ok true)
  )
)

;; Withdraw STX collected from token generation
(define-public (withdraw-stx (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (as-contract (stx-transfer? amount tx-sender recipient)))
    (ok true)
  )
)

;; Get contract STX balance
(define-read-only (get-contract-stx-balance)
  (stx-get-balance (as-contract tx-sender))
)

;; Read-only functions for current parameters
(define-read-only (get-generation-params)
  {
    generation-rate: (var-get generation-rate),
    generation-cost: (var-get generation-cost),
    min-blocks-between-generation: (var-get min-blocks-between-generation),
    max-supply: (var-get max-supply)
  }
)
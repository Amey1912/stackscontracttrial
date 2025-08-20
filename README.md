🪙 Token Generator & Swap Contract (Stacks / Clarity)

Deployed Contract Address

ST3WJDDYB6R0PTWYRF6700T0MAY97DS0QVSGAZSNA.storage-contract1![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.001.png)

📜 Overview

This smart contract enables users to generate tokens by paying STX and securely swap them through an escrow-based marketplace on Stacks. It features rate limiting, maximum supply controls, time- based swap expiry, and comprehensive security measures.

<img width="801" height="1185" alt="image" src="https://github.com/user-attachments/assets/cf62cc7a-ca14-4fd9-9c19-6faea153d5e1" />


Show Image![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.002.png)

⭐ Features

- Generate Tokens by paying STX with rate limiting protection
- Secure Token Swaps with escrow system and expiry controls
- Rate Limiting prevents spam generation (144 blocks between generations)
- Maximum Supply cap to prevent unlimited inflation
- Time-Based Expiry for swap offers with automatic cleanup
- Admin Controls for generation parameters and fee collection
- Comprehensive Error Handling with descriptive error codes

⚙ Error Codes



|u100|ERR-OWNER-ONLY → Admin function called by non-owner|
| - | - |
|u101|ERR-INSUFFICIENT-BALANCE → Not enough tokens for operation|
|u102|ERR-INVALID-AMOUNT → Amount must be greater than zero|
|u103|ERR-UNAUTHORIZED → Caller not authorized for this action|
|u104|ERR-SWAP-NOT-FOUND → Swap ID does not exist|
|u105|ERR-SWAP-EXPIRED → Swap offer has expired|
|u106|ERR-SWAP-ALREADY-EXECUTED → Swap already completed or cancelled|
|u107|ERR-INVALID-SWAP-ID → Invalid swap identifier|
|u108|ERR-TOO-SOON → Must wait before generating tokens again|
|u109|ERR-EXCEEDS-MAX-SUPPLY → Would exceed maximum token supply|
|||
📦 Contract Functions

Token Generation

generate-tokens ()![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.003.png)

Generates new tokens by paying STX with built-in rate limiting. Flow:

- Verify minimum blocks have passed since last generation (144 blocks ≈ 1 day)
- Check that generation won't exceed maximum supply
- Transfer STX cost from caller to contract
- Mint tokens to caller
- Update generation tracking

Example:

clarity![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.004.png)

((ccoonnttrraacctt--ccaallll??  ..ssttoorraaggee--ccoonnttrraacctt11  ggeenneerraattee--ttookkeennss))

Token Swapping

create-swap (token-amount uint) (stx-amount uint) (counterparty optional principal) (duration uint)![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.005.png)

Creates a new swap offer with tokens escrowed in the contract. Parameters:

- token-amount → Number of tokens to offer![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.006.png)
- stx-amount → STX amount requested in return![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.007.png)
- counterparty → Optional specific buyer (none for public offer)![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.008.png)
- duration → Blocks until expiry![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.009.png)

Example:

clarity![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.010.png)

((ccoonnttrraacctt--ccaallll??  ..ssttoorraaggee--ccoonnttrraacctt11  ccrreeaattee--sswwaapp  uu11000000  uu55000000000000  nnoonnee  uu114444)) execute-swap (swap-id uint)![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.011.png)

Execute an existing swap offer by paying the requested STX. Example:

clarity![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.012.png)

((ccoonnttrraacctt--ccaallll??  ..ssttoorraaggee--ccoonnttrraacctt11  eexxeeccuuttee--sswwaapp  uu11)) cancel-swap (swap-id uint)![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.013.png)

Cancel your own swap offer and retrieve escrowed tokens. Example:

clarity![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.014.png)

((ccoonnttrraacctt--ccaallll??  ..ssttoorraaggee--ccoonnttrraacctt11  ccaanncceell--sswwaapp  uu11))

Read-Only Functions

get-balance (who principal) → Get token balance for address ![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.015.png)get-total-supply () → Get current total token supply![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.016.png)

get-token-info () → Get token metadata (name, symbol, decimals, supply) ![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.017.png)get-swap (swap-id uint) → Get swap details by ID![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.018.png)

get-generation-stats (user principal) → Get user's generation statistics ![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.019.png)get-generation-params () → Get current generation parameters![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.020.png)

🛠 Setup & Usage

Local Deployment (Clarinet)

bash![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.021.png)

ccllaarriinneett  nneeww  ttookkeenn--ggeenneerraattoorr--sswwaapp ccdd  ttookkeenn--ggeenneerraattoorr--sswwaapp

\##  AAdddd  ssttoorraaggee--ccoonnttrraacctt11..ccllaarr  ttoo  ccoonnttrraaccttss//  ddiirreeccttoorryy

ccllaarriinneett  cchheecckk ccllaarriinneett  ccoonnssoollee

\##  TTeesstt  iinn  ccoonnssoollee

((ccoonnttrraacctt--ccaallll??  ..ssttoorraaggee--ccoonnttrraacctt11  ggeett--ttookkeenn--iinnffoo)) ((ccoonnttrraacctt--ccaallll??  ..ssttoorraaggee--ccoonnttrraacctt11  ggeenneerraattee--ttookkeennss))

On Testnet / Mainnet

1. Deploy using Clarinet or Stacks CLI
1. Open contract in Stacks Explorer
1. Call  generate-tokens to mint your first tokens![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.022.png)
1. Create swap offers with  create-swap![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.023.png)
1. Execute swaps from other accounts

GitHub Actions Deployment

Set up automated deployment with GitHub Actions:

1. Add workflow file to  .github/workflows/deploy.yml![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.024.png)
1. Set  TESTNET\_MNEMONIC secret in repository settings![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.025.png)
1. Push to main branch to trigger deployment

📊 Token Economics



|Default Value||||
| - | :- | :- | :- |
|Generation Rate|1,000 tokens|Tokens minted per generation||
|Generation Cost|1,000,000 µSTX|STX cost to generate tokens||
|Rate Limit|144 blocks|Minimum blocks between generations||
|Max Supply|1,000,000,000,000|Maximum total token supply||
|Decimals|6|Token decimal precision||
|||||
📄 Security Features

Rate Limiting

- Users can only generate tokens once every 144 blocks (~24 hours)
- Prevents spam attacks and controls token inflation

Escrow System

- Tokens are locked in contract during active swaps
- Automatic return on cancellation or expiry
- No double-spending possible

Access Controls

- Admin-only functions for parameter updates
- Owner verification for sensitive operations
- Clear authorization checks throughout

Expiry Management

- Time-based swap expiry prevents stale offers
- Automatic cleanup of expired swaps
- Block height validation for all time-sensitive operations

🔧 Admin Functions (Owner Only)

set-generation-params (rate uint) (cost uint) (min-blocks uint)![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.026.png)

Update token generation parameters.

withdraw-stx (amount uint) (recipient principal)![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.027.png)

Withdraw collected STX fees from token generation.

get-contract-stx-balance ()![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.028.png)

Check contract's STX balance from collected fees.

👩‍💻 Tech Stack

Language: Clarity (Stacks Smart Contracts)

Tools: Clarinet, Stacks CLI, GitHub Actions Network: Stacks Testnet/Mainnet

Token Standard: Custom with transfer functionality

🚀 Future Enhancements

- Integration with SIP-010 fungible token standard
- Advanced swap matching algorithms
- Liquidity pool integration
- Governance token functionality
- Multi-token swap support

📞 Support

For issues or questions:

- Create an issue in this repository
- Check Stacks documentation
- Join Stacks Discord community![](Aspose.Words.c4d59ef8-b59c-4d17-952b-e4fc866ca7b2.029.png)

⚠ Disclaimer: This contract is for educational/experimental purposes. Always audit smart contracts before mainnet deployment with real funds.



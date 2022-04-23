# Nane Contracts

Please visit the [Nane Website](https://nane.fi) for more information about the project. Smart contracts are not audited yet. Use at your own risk.

This repository includes Launchpad, Project Registry and Token smart contracts.

## Requirements

`eth-brownie` is enough to compile the smart contracts.

## Sales

#### [LiquiditySale](contracts/sales/LiquiditySale.vy)

Nane Liquidity Sale supports discounts for beta token holders and automatically adds liquidity to the [PancakeSwap](https://pancakeswap.finance).


#### [LaunchpadRegistry](contracts/sales/LaunchpadRegistry.vy)

Sale registry holds metadata related to token sales and assign sale IDs.


## Tokens

#### [Beta Token](contracts/beta/BetaToken.vy)

Beta token is a ERC20 token which cannot be transferred. This token can be minted or burned by the minter.

It will be possible to migrate Beta Token with  [Token](contracts/Token.vy) once first sale ends.

#### [Token](contracts/Token.vy)

ERC20 token with fixed supply.
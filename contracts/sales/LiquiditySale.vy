# @version 0.3.1
"""
@title Nane Liquidity Sale
@license MIT
@author nane.fi
@notice
    This sale raises liquidity on the UNI-V2 compatible AMM and transfers
    specific percentage of the sale earnings to the "beneficiary". Token is
    immediately transferred and liquidity is added within the purchase() function.

    Also, there are discounts for people holding specific ERC20 token. In this
    case, this rewards our beta program testers and early community members.
"""
from vyper.interfaces import ERC20

interface IRouter:
    def addLiquidityETH(
        token: address,
        amountTokenDesired: uint256,
        amountTokenMin: uint256,
        amountETHMin: uint256,
        to: address,
        deadline: uint256
    ) -> (uint256, uint256, uint256): payable


saleToken: public(ERC20)
betaToken: public(ERC20)
router: public(IRouter)

#   Sale's starting and ending timestamp
saleDates: public(uint256[2])
#   Token sale amount
saleAmount: public(uint256)
#   Liquidity amount in tokens
liquidityAmount: public(uint256)
#   Amount liquidity is going to get in percentage
liquidityShare: public(uint256)
#   Total tokens sold through sale
sold: public(uint256)
# Price per token
tokenPrice: public(uint256)
#   Beneficiary of sale
#   This address only receives some percentage of the sale as
#   specified in the saleShares
beneficiary: public(address)


@external
def __init__(
    _saleToken: address,
    _betaToken: address,
    _router: address,
    _saleDates: uint256[2],
    _liquidityShare: uint256,
    _saleAmount: uint256,
    _liquidityAmount: uint256,
    _tokenPrice: uint256,
    _beneficiary: address
):
    self.saleToken = ERC20(_saleToken)
    self.betaToken = ERC20(_betaToken)
    self.router = IRouter(_router)
    self.saleDates = _saleDates
    self.liquidityShare = _liquidityShare
    self.saleAmount = _saleAmount
    self.liquidityAmount = _liquidityAmount
    self.tokenPrice = _tokenPrice
    self.beneficiary = _beneficiary

    #   Approve sale tokens to be spent on Router
    #   This is required for adding liquidity
    self.saleToken.approve(_router, MAX_UINT256)


@external
@payable
def __default__():
    #   This function is likely called from the UNI-V2 AMM after adding liquidity
    #   This sends any funds received to the sale beneficiary
    send(self.beneficiary, self.balance)


@internal
def _addLiquidity(liquidityTokens: uint256, amountInETH: uint256):
    liquidity: uint256 = min(
        min(liquidityTokens, self.liquidityAmount),
        self.saleToken.balanceOf(self)
    )

    if (liquidity > 0) and (amountInETH > 0):
        #   Adds liquidity to the UNI-V2 pair in ETH
        self.liquidityAmount -= self.router.addLiquidityETH(
            self.saleToken.address,
            liquidity,
            0,
            0,
            ZERO_ADDRESS,
            block.timestamp,
            value=amountInETH
        )[0]


@view
@internal
def _calculate(buyer: address, amountInETH: uint256) -> uint256:
    #   Working with decimals allows more precise conversion between token prices
    #   while still keeping the calculation simple.
    salePrice: decimal = convert(self.tokenPrice, decimal) / 1e18
    buyerGets: decimal = (convert(amountInETH, decimal) / 1e18) / salePrice

    if self.betaToken.balanceOf(buyer) > 0:
        buyerGets = buyerGets * 1.5

    return convert(buyerGets * 1e18, uint256)


@view
@external
def calculate(
    amountInETH: uint256
) -> uint256:
    """
    @notice
        Calculate amount to receive in sale tokens
    @param amountInETH
        Purchase amount in ETH
    @return
        Amount, in sale tokens
    """
    return self._calculate(ZERO_ADDRESS, amountInETH)


@view
@external
def price() -> (address, uint256):
    """
    @notice
        Get token price
    @return
        Purchase token, price in purchase token per sale token
    """
    return (
        ZERO_ADDRESS,
        self.tokenPrice
    )


@view
@external
def saleDate() -> (uint256, uint256):
    """
    @notice
        Get sale dates
    @return
        Sale start timestamp, sale ending timestamp
    """
    return (
        self.saleDates[0], 
        self.saleDates[1]
    )


@payable
@external
def purchase():
    """
    @notice
        Purchase tokens while adding liquidity.
        Liquidity will be added and tokens will be sent instantly.
    @dev
        Sale must be ongoing.
        User must receive more than 0 tokens.
    """
    #   Check if sale already started or ended
    assert (self.saleDates[1] >= block.timestamp) and (
        block.timestamp >= self.saleDates[0]
    ), "Sale::purchase: Current timestamp not eligible"

    buyerGets: uint256 = self._calculate(msg.sender, msg.value)
    assert (self.saleAmount - self.sold) >= buyerGets, "Sale::purchase: Not enough tokens"
    self.sold += buyerGets
    self.saleToken.transfer(msg.sender, buyerGets)

    liquidity: uint256 = msg.value / self.liquidityShare
    self._addLiquidity(self._calculate(ZERO_ADDRESS, liquidity), liquidity)

    #   Remaining balance is sent to beneficiary after liquidity is added
    send(self.beneficiary, self.balance)



@external
def burn():
    """
    @notice
        Burn remaining sale tokens in this contract after sale ends
    @dev
        Reverts if sale did not end yet.
    """
    assert block.timestamp > self.saleDates[1], "Sale::burn: Sale did not end"

    self.saleToken.transfer(
        ZERO_ADDRESS,
        self.saleToken.balanceOf(self)
    )
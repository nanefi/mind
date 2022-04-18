# @version 0.3.1
"""
@title Nane Token
@license MIT
@author nane.fi
@notice
    Nane Token is fixed supply ERC20 token. This means token supply 
    cannot be changed by anyone.
"""
from vyper.interfaces import ERC20

implements: ERC20

# -- Token Events --
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256


event Approval:
    owner: indexed(address)
    receiver: indexed(address)
    amount: uint256


name: public(String[64])
symbol: public(String[32])
decimals: public(uint8)
totalSupply: public(uint256)

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])


@external
def __init__(
    name: String[64], symbol: String[32], totalSupply: uint256, decimals: uint8
):
    self.name = name
    self.symbol = symbol
    self.totalSupply = totalSupply
    self.decimals = decimals
    self.balanceOf[msg.sender] = totalSupply

    log Transfer(ZERO_ADDRESS, msg.sender, totalSupply)


@internal
def _burn(owner: address, amount: uint256):
    self.totalSupply -= amount
    self.balanceOf[owner] -= amount

    log Transfer(owner, ZERO_ADDRESS, amount)


@external
def transfer(receiver: address, amount: uint256) -> bool:
    """
    @notice Transfer tokens
    @param receiver Address of receiver
    @param amount Amount of transfer
    """
    self.balanceOf[msg.sender] -= amount
    self.balanceOf[receiver] += amount

    log Transfer(msg.sender, receiver, amount)
    return True


@external
def transferFrom(owner: address, receiver: address, amount: uint256) -> bool:
    """
    @notice Transfer tokens from owner
    @param owner Address of owner of the amount, who also provided necessary
    allowance to the `msg.sender`
    @param receiver Address of receiver
    @param amount Amount of transfer
    """
    self.allowance[owner][msg.sender] -= amount
    self.balanceOf[owner] -= amount
    self.balanceOf[receiver] += amount

    log Transfer(owner, receiver, amount)
    return True


@external
def approve(receiver: address, amount: uint256) -> bool:
    """
    @notice Approve tokens to be spent by receiver
    @param receiver Address of receiver
    @param amount Amount of allowance
    """
    self.allowance[msg.sender][receiver] = amount

    log Approval(msg.sender, receiver, amount)
    return True


@external
def burn(amount: uint256):
    """
    @notice Burn tokens and decrease token total supply
    @param amount Amount to burn
    """
    self._burn(msg.sender, amount)
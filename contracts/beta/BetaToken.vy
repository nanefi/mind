# @version 0.3.1
"""
@title Nane Beta Token
@license MIT
@author nane.fi
@notice
    Nane Beta Token is used to reward early contributors of project.
    This token cannot be transferred, for this reason token also shows
    specific address contributed to the project.

    During the beta program, rewards will be minted through this token.
    Once beta program ends, Nane Beta Token holders will get chance to
    migrate their tokens with completely transferable ERC20 token.
"""
from vyper.interfaces import ERC20
implements: ERC20

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256


event Approval:
    owner: indexed(address)
    receiver: indexed(address)
    amount: uint256


event AddMinter:
    minter: indexed(address)


event RemoveMinter:
    minter: indexed(address)


name: public(String[32])
symbol: public(String[8])
decimals: public(uint8)
totalSupply: public(uint256)

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

minter: public(HashMap[address, bool])


@external
def __init__(name: String[32], symbol: String[8], decimals: uint8):
    self.name = name
    self.symbol = symbol
    self.decimals = decimals

    self.minter[msg.sender] = True
    log AddMinter(msg.sender)


@external
def transfer(receiver: address, amount: uint256) -> bool:
    assert False, "beta: no transfers"
    return True


@external
def transferFrom(owner: address, receiver: address, amount: uint256) -> bool:
    assert False, "beta: no transfers"
    return True


@external
def approve(receiver: address, amount: uint256) -> bool:
    assert False, "beta: no transfers"
    return True


@external
def mint(receiver: address, amount: uint256):
    assert self.minter[msg.sender]
    self.balanceOf[receiver] += amount
    self.totalSupply += amount

    log Transfer(ZERO_ADDRESS, receiver, amount)


@external
def burn(owner: address, amount: uint256):
    assert self.minter[msg.sender]
    self.balanceOf[owner] -= amount
    self.totalSupply -= amount

    log Transfer(owner, ZERO_ADDRESS, amount)


@external
def addMinter(_minter: address):
    assert self.minter[msg.sender]
    self.minter[_minter] = True
    log AddMinter(_minter)


@external
def removeMinter(_minter: address):
    assert self.minter[msg.sender]
    self.minter[_minter] = False
    log RemoveMinter(_minter)
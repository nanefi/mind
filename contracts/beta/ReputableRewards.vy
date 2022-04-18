# @version 0.3.1
"""
@title Reputable Rewards
@license MIT
@author nane.fi
@notice
    Projects on the Nane Reputable Registry are listed by the "group".
    This group can be decentralized governance or in this case group of
    early contributors.

    Anyone can request to list projects there and it needs to be approved
    by owner of this smart contract. If project listing request is approved,
    creator of the request will receive listing rewards.
"""

interface IBetaToken:
    def mint(receiver: address, amount: uint256): nonpayable


interface IReputable:
    def tokenToProject(token: address) -> uint256: view
    def createId(chId: uint256, token: address, metadata: String[64]): nonpayable


struct Project:
    chId: uint256
    token: address
    metadata: String[64]
    banned: bool
    lastUpdated: uint256


struct Listing:
    chId: uint256
    token: address
    creator: address


event ListingRequest:
    creator: indexed(address)
    token: indexed(address)


event ApproveRequest:
    group: indexed(address)
    requestId: uint256


reputable: public(IReputable)
listingReward: public(uint256)
rewardToken: public(IBetaToken)

requests: public(HashMap[uint256, Listing])
lastRequest: public(uint256)

owner: public(address)


@external
def __init__(_reputable: address, _listingReward: uint256, _rewardToken: address):
    self.reputable = IReputable(_reputable)
    self.listingReward = _listingReward
    self.rewardToken = IBetaToken(_rewardToken)

    self.owner = msg.sender


@external
def requestListing(chId: uint256, token: address):
    """
    @notice Request new listing
    @param chId Chain ID of token
    @param token Token address
    """
    requestId: uint256 = self.lastRequest
    self.lastRequest += 1

    assert self.reputable.tokenToProject(token) == 0, "requestListing: Token already exist"
    self.requests[requestId] = Listing({
        chId: chId,
        token: token,
        creator: msg.sender
    })

    log ListingRequest(msg.sender, token)


@external
def approveListing(requestId: uint256, metadata: String[64]):
    """
    @notice Approve listing
        Transfer creator of listing a listing reward in reward token
    @param requestId Request ID of listing to approve
    @param metadata Updated metadata
    @dev Only group can approve listing
    """
    assert msg.sender == self.owner

    listing: Listing = self.requests[requestId]

    self.reputable.createId(listing.chId, listing.token, metadata)
    self.rewardToken.mint(listing.creator, self.listingReward)
    log ApproveRequest(msg.sender, requestId)
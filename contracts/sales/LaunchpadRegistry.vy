# @version 0.3.1
"""
@title Nane Launchpad Registry
@license MIT
@author nane.fi
@notice
    Nane Launchpad Registry allows listing of multiple sales given 
    that they support "Launcher" interface. However, listings need
    to be approved by the governance.
"""


struct Sale:
    token: address
    #  There can be several types of sale contracts
    #  however sale contracts share similar functions
    #  This means they will be compatible with registy.
    launcher: address
    name: String[64]
    #  Metadata can be helpful to include additional stuff
    #  such as sale description, reason and how funds will
    #  be distributed after the sale.
    metadata: String[64]

interface Launcher:
    def sold() -> uint256: view
    def price() -> (address, uint256): view
    def saleAmount() -> uint256: view
    def saleToken() -> address: view
    def saleDate() -> (uint256, uint256): view


event ListSale:
    lister: indexed(address)
    launcher: indexed(address)
    token: indexed(address)


event UpdateSale:
    saleId: indexed(uint256)


event ChangeGroup:
    group: indexed(address)
    status: bool


#   This is working group which is responsible for listing 
#   of new sales
group: public(HashMap[address, bool])

#   List of sales
sales: public(HashMap[uint256, Sale])
lastSaleId: public(uint256)


@external
def __init__(_group: address):
    self.group[_group] = True
    self.lastSaleId = 1


@external
def listSale(
    launcher: address,
    name: String[64],
    metadata: String[64]
) -> uint256:
    """
    @notice
        List a new sale on launchpad
    @param launcher
        Address of sale contract
        This sale contract must be compatible with Launcher interface
        as some functions in this registry are dependent on the Launcher
        functions.
    @param name
        Name of sale
    @param metadata
        Sale metadata
        This is used within the front-end for showing details about
        the sale.
    @return
        Sale ID
    @dev
        Only group can list new sales.
    """
    assert self.group[msg.sender]

    saleId: uint256 = self.lastSaleId
    self.lastSaleId += 1

    saleToken: address = Launcher(launcher).saleToken()

    self.sales[saleId] = Sale({
        token: saleToken,
        launcher: launcher,
        name: name,
        metadata: metadata
    })

    log ListSale(msg.sender, launcher, saleToken)

    return saleId


@external
def editSale(
    saleId: uint256,
    name: String[64],
    metadata: String[64]
):
    """
    @notice
        Change name and metadata of an sale
    @param saleId
        Sale ID
    @param name
        Sale name
    @param metadata
        Sale metadata
    @dev
        Only group can edit sale
        Sale token must not be ZERO_ADDRESS
    """
    assert self.group[msg.sender]
    assert self.sales[saleId].token != ZERO_ADDRESS

    self.sales[saleId].name = name
    self.sales[saleId].metadata = metadata

    log UpdateSale(saleId)


@view
@external
def saleDate(
    saleId: uint256
) -> (uint256, uint256):
    """
    @notice
        Get important timestamps for sale
    @param saleId
        Sale ID
    @return
        Sale start, sale end
    """
    return Launcher(self.sales[saleId].launcher).saleDate()


@view
@external
def saleAmount(
    saleId: uint256
) -> uint256:
    """
    @notice
        Get sale amount in sale token
    @param saleId
        Sale ID
    @return
        Sale amount
    """
    return Launcher(self.sales[saleId].launcher).saleAmount()


@view
@external
def saleSold(
    saleId: uint256
) -> uint256:
    """
    @notice
        Total amount of tokens sold through sale
    @param saleId
        Sale ID
    @return
        Tokens sold
    """
    return Launcher(self.sales[saleId].launcher).sold()


@view
@external
def price(
    saleId: uint256
) -> (address, uint256):
    """
    @notice
        Fetch price of a sale through launcher
    @param saleId
        Sale ID
    @return
        Token you need to pay with and price per sale token
    """
    return Launcher(self.sales[saleId].launcher).price()


@external
def changeGroup(_group: address, status: bool):
    """
    @notice
        Change group status
    @param _group
        Group to change status
    @param status
        New group status
        If True, this address will have access to listing new sales.
        If False, this address will no longer have access to listing 
        new sales.
    @dev
        Only current group can change status of a group
    """
    assert self.group[msg.sender]  # dev: not group
    self.group[_group] = status

    log ChangeGroup(_group, status)

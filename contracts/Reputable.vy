# @version 0.3.1
"""
@title Nane Reputable Registry
@license MIT
@author nane.fi
@notice
    Nane Reputable Registry aims to create decentralized registry of projects
    through all EVM compatible networks using decentralized governance.
    Projects listed here are aimed to be controlled by decentralized governance
    to increase the quality of projects listed here.

    Project details are stored in Project struct as metadata. This metadata can
    be stored anywhere including Arweave or IPFS and metadata content can be 
    changed freely as long as decentralized governance approves the change.

    Group is group of owners. Optimally, this should not be an EOA to increase
    the decentralization of Reputable Registry.
"""
from vyper.interfaces import ERC20


struct Project:
    # Chain where project is available
    chId: uint256
    # Token address
    token: address
    # Metadata of token approved by DAO
    metadata: String[64]
    # Ban status
    banned: bool
    # Last update date
    lastUpdated: uint256


# --- Projects ---
projects: public(HashMap[uint256, Project])
tokenToProject: public(HashMap[address, uint256])
lastProjectId: public(uint256)

# Management
group: public(HashMap[address, bool])

@external
def __init__(_group: address):
    self.group[_group] = True
    self.lastProjectId = 1


@internal
def _updatedProject(projectId: uint256):
    self.projects[projectId].lastUpdated = block.timestamp


@external
def createId(chId: uint256, token: address, metadata: String[64]):
    """
    @notice Create a new project
    @param chId Chain ID of project
    @param token Token of project
    @param metadata Metadata of project
    @dev Project must not exist before
    """
    assert self.group[msg.sender]
    projectId: uint256 = self.lastProjectId
    self.lastProjectId += 1

    assert self.tokenToProject[token] == 0, "Reputable::createId: Token already exist"
    self.projects[projectId] = Project({
        chId: chId,
        token: token,
        metadata: metadata,
        banned: False,
        lastUpdated: block.timestamp
    })
    self.tokenToProject[token] = projectId


@external
def banId(projectId: uint256, reason: String[64]):
    """
    @notice Ban specific projectId from registry.
    Ban reason will be replaced with the metadata.
    @param projectId Unique ID of the project
    @param reason IPFS hash where reason of ban is available
    @dev Requires admin interaction
    """
    assert self.group[msg.sender]
    self.projects[projectId].banned = True
    self._updatedProject(projectId)


@external
def appealId(projectId: uint256):
    """
    @notice Remove ban of specific projectId from registry
    @param projectId Unique ID of the project
    @dev Requires admin interaction
    """
    assert self.group[msg.sender]
    assert self.projects[projectId].banned, "Reputable::appealId: Project not banned"
    self.projects[projectId].banned = False
    self._updatedProject(projectId)


@external
def updateId(projectId: uint256, metadata: String[64]):
    """
    @notice Update specific projectId
    @param projectId Unique ID of the project
    @param metadata Updated IPFS hash which contains the metadata
    """
    assert self.group[msg.sender]
    assert projectId != 0, "Reputable::updateId: 0 cannot be used"
    self.projects[projectId].metadata = metadata
    self._updatedProject(projectId)


@external
def changeGroup(_group: address, status: bool):
    """
    @notice Change status of an group
    @param _group Address to change status of
    @param status New group status
    """
    assert self.group[msg.sender] # dev: not group
    self.group[_group] = status
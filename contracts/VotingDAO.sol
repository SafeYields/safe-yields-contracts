// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/ISafeNFT.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "./interfaces/IVotingDAO.sol";

contract VotingDAO is IVotingDAO, Proxied {
    ISafeNFT public safeNFT;

    Proposal[] public proposals;

    modifier onlySafeNFTOwner() {
        require(safeNFT.votingPower(msg.sender) > 0, "Only Safe NFT owners can call this function");
        _;
    }

    function initialize(address _safeNFT) public proxied {
        safeNFT = ISafeNFT(_safeNFT);
    }
    constructor (address _safeNFT) {
        initialize(_safeNFT);
    }


    function addProposal(string memory _description) public onlyProxyAdmin {
        proposals.push();
        Proposal storage proposal = proposals[proposals.length - 1];
        proposal.description = _description;
        proposal.status = Status.Open;
        emit ProposalAdded(proposals.length - 1, _description);
    }

    function vote(uint _proposalId, Vote _vote) public onlySafeNFTOwner {
        Proposal storage proposal = proposals[_proposalId];

        require(proposal.status == Status.Open, "Proposal is not open");
        require(proposal.votesByMember[msg.sender] == Vote.NoVote, "You have already voted");

        if (_vote == Vote.Yes) {
            proposal.yesVotes += safeNFT.votingPower(msg.sender);
        } else if (_vote == Vote.No) {
            proposal.noVotes += safeNFT.votingPower(msg.sender);
        } else
            revert("Invalid vote, only Yes (1) or No (2)");
        proposal.votesByMember[msg.sender] = _vote;
        emit VoteCasted(_proposalId, msg.sender, uint(_vote));
    }

    function closeProposal(uint _proposalId) public onlyProxyAdmin {
        Proposal storage proposal = proposals[_proposalId];

        require(proposal.status == Status.Open, "Proposal is not open");

        proposal.status = Status.Closed;
        emit ProposalClosed(_proposalId);
    }

    function getProposal(uint _proposalId) public view returns (string memory description, uint yesVotes, uint noVotes, Status status) {
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.description, proposal.yesVotes, proposal.noVotes, proposal.status);
    }

}

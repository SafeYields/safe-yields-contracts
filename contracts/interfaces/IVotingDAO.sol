// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVotingDAO {
    event ProposalAdded(uint indexed proposalId, string description);
    event VoteCasted(uint indexed proposalId, address indexed voter, uint indexed vote);
    event ProposalClosed(uint indexed proposalId);

    enum Status {Open, Closed}
    enum Vote {NoVote, Yes, No}

    struct Proposal {
        string description;
        uint yesVotes;
        uint noVotes;
        Status status;
        mapping(address => Vote) votesByMember;
    }

    /**
    @notice This function adds a new proposal to the list of proposals.
    @param _description The description of the proposal.
    */
    function addProposal(string memory _description) external;

    /**
    @notice This function allows Safe NFT owners to vote on a proposal.
    @param _proposalId The ID of the proposal.
    @param _vote The vote (Yes 1 or No 2).
    */
    function vote(uint _proposalId, Vote _vote) external;

    /**
    @notice This function allows the admin to close a proposal.
    @param _proposalId The ID of the proposal.
    */
    function closeProposal(uint _proposalId) external;

    /**
    @notice This function returns the details of a proposal.
    @param _proposalId The ID of the proposal.
    @return description The description of the proposal.
    @return yesVotes The number of yes votes.
    @return noVotes The number of no votes.
    @return status The status of the proposal (Open or Closed).
    */
    function getProposal(uint _proposalId) external view returns (string memory description, uint yesVotes, uint noVotes, Status status);
}

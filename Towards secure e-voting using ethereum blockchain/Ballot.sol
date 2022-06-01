pragma solidity >=0.4.22 <0.6.0;

/*
*Group 5
* Implementation of "Towards secure e-voting using ethereum blockchain, Yavuz, Emre, et al.
* This complete code is implemented by @Group5 based on the above paper.
*/

contract Ballot {
    struct Candidate {
        string name;
        uint voteCount;
    }
    
    struct Voter {
        bool authorized;
        bool voted;
        uint vote;
    }
    
    //state variables: owner, electioName, voters, candidates, totalVotes = > these are the data of this contract and these data are stored in the blockchain as state of this contract.  
    address payable public owner;
    string public electionName;
    uint voteStartTime;
    uint voteEndTime;
    
    mapping(address => Voter) public voters;
    Candidate[] public candidates; //array of candidates
    uint public totalVotes; //total votes received so far in the election
    
    modifier ownerOnly() {
        require (msg.sender ==owner);
        _; //execute remaining parts from the functions where this modifier is used (e.g., addCandidate) after doing the above check 
    }
    
    constructor(string memory _name, uint _amountOfVotingHours) public {
      // Set the creator of contract as owner of the contract (e.g., election administrator)
      owner = msg.sender;
      electionName = _name;
      voteStartTime = now;
      voteEndTime = now + _amountOfVotingHours;
    }
    
    function addCandidate(string memory _name) ownerOnly public {
        candidates.push(Candidate(_name, 0)); //sets new candidate name and 0: no votes received as it is a new candidate 
    }
    
    //function to get the number of candidates 
    //view: this function doesn't change any state varible value of this program
    function getNumCandidate () public view returns (uint) {
        return candidates.length;
    }
    
    function getCandidateName(uint _voteIndex) public view returns (string memory) {
        require(now < voteEndTime, "Voting time expired");
        return candidates[_voteIndex].name;
    }
    
    //function to authorize a voter
    function authorize (address _person) ownerOnly public {
        voters[_person].authorized = true;
    }
    
	//Voting phase
    function vote(uint _voteIndex) public {
        require(now < voteEndTime, "Voting time expired");
        require(!voters[msg.sender].voted);
        require(voters[msg.sender].authorized);
        
        voters[msg.sender].vote = _voteIndex;
        voters[msg.sender].voted = true;
        
        candidates[_voteIndex].voteCount += 1;
        totalVotes += 1;
    }
    
    //Get result of election
    function voteResult() public view returns (string memory, uint) {
        require(now > voteEndTime, "Vote has not ended");
        uint winningVoteCount = 0;
        uint winningCandidate;
        for (uint vidx = 0; vidx < candidates.length; vidx++){
            if (candidates[vidx].voteCount > winningVoteCount) {
                winningVoteCount = candidates[vidx].voteCount;
                winningCandidate = vidx;
            }
        }
        return (candidates[winningCandidate].name, candidates[winningCandidate].voteCount);
    }
    
    function endVote() public ownerOnly {
        require(now < voteEndTime, "Voting already closed.");
        voteEndTime = now;
    }
    
   function close() public ownerOnly { //onlyOwner is custom modifier
            selfdestruct(owner);  // `owner` is the owners address
    }
    
/*    
    function votingTimes() public view returns (uint, uint){
        return (voteStartTime, voteEndTime);
    }
    
    function currentTime() public view returns (uint){
        return now;
    }
*/    
}

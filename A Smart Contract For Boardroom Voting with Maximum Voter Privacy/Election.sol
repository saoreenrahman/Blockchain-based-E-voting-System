pragma solidity ^0.4.10;
import "./CryptoLib.sol";
/*
* Group 5  
* Code usage declaration:
** For our implementation we have used the open source code provided by the author of
** "A Smart Contract For Boardroom Voting with Maximum Voter Privacy". 
** Original code source published by P. McCorry at: https://github.com/stonecoldpat/anonymousvoting
*** We have used the provided "ECCMath_noconflict" library and the "Secp256k1_noconflict" library 
*** without any modifications.
*** For rest of codes, we mentioned @group5 to represent our original code.
*** For the funtions where we modified McCorry's code we wrote the modifications.
*** For the funtions where we used McCorry's code without any modification we mentioned "CodeCredit: @Patrick McCorry"
*/



contract Election{
      // Modulus for public keys
  uint constant pp = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

  // Base point (generator) G
  uint constant Gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint constant Gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;

  // New  point (generator) Y
  uint constant Yx = 98038005178408974007512590727651089955354106077095278304532603697039577112780;
  uint constant Yy = 1801119347122147381158502909947365828020117721497557484744596940174906898953;

  // Modulus for private keys (sub-group)
  uint constant nn = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

  uint[2] G;
  uint[2] Y;
  

  struct Voter {
      address addr;
      uint[2] registeredkey;
      uint[2] reconstructedkey;
      uint[2] vote;
      uint voted;
    }
  
    address[] public addresses;
    mapping (address => uint) public addressid; // Address to Counter
    mapping (uint => Voter) public voters;
    uint totalCountedVote;
    mapping (address => bool) public eligible; // White list of addresses allowed to vote
    mapping (address => bool) public registered; // Address registered?
    mapping (address => bool) public votecast; // Address voted?
  
    uint public finishSignupPhase; // Election Authority to transition to next phase.
    uint public endSignupPhase; // Election Authority does not transition to next phase by this time.
    uint public endVoting; // Voters have not submitted their vote by this stage.
    
    string public question; //Election name
    uint public totalregistered; //Total number of participants that have submited a voting key
    uint public totaleligible;
    uint public totalvoted;
    uint[2] finaltally; // Final tally
    
    address public owner;
    modifier onlyOwner {
        if(owner != msg.sender) throw;
        _;
    }
    

  function Election() {
    owner = msg.sender;
    G[0] = Gx;
    G[1] = Gy;

    Y[0] = Yx;
    Y[1] = Yy;
  }

    
    //======================== set eligible voters ================================
    //CodeCredit @Patrick McCorry
    function setEligible(address[] addr) onlyOwner {
        // Sign up the addresses
        for(uint i=0; i<addr.length; i++) {
            if(!eligible[addr[i]]) {
                eligible[addr[i]] = true;
                addresses.push(addr[i]);
                totaleligible += 1;
            }
        }
    }
    
    
    //======================= set candidates ====================================
    //@group5
    struct Candidate {
        string name;
        uint voteReceived;
        string result;
    }
    
    Candidate[] candidates; //array of candidates
    function addCandidate(string memory _name) onlyOwner public {
        candidates.push(Candidate(_name, 0, "no result yet")); //sets new candidate name and 0: no votes received as it is a new candidate 
    }
    
    
    
    //==================== initialize ================================================
    //CodeCredit @Patrick McCorry
    //Modification: McCorry's work uses gap (between phases), that is set during the contract deployment. 
    // Instead of setting the gap time every time we depolyed the contract testing, here we kept it fixed.
    // We also use just a single timer to keep track of election duration
    function beginSignUp(string _electionName, uint _electionDuration) onlyOwner {
        uint gap =500;
        question = _electionName;
        finishSignupPhase = _electionDuration;
        endSignupPhase = finishSignupPhase + gap;        
        uint _endComputation = endSignupPhase + gap;
        endVoting = _endComputation + gap; 
    }
    
    //====================== registration =========================================
     //CodeCredit @Patrick McCorry
     function register(uint[2] xG, uint[3] vG, uint r) {
        // Only white-listed addresses can vote
        if(eligible[msg.sender]) {
            if(verifyZKP(xG,r,vG) && !registered[msg.sender]) {
                uint[2] memory empty;
                addressid[msg.sender] = totalregistered;
                voters[totalregistered] = Voter({addr: msg.sender, registeredkey: xG, reconstructedkey: empty, vote: empty, voted: 0});
                registered[msg.sender] = true;
                totalregistered += 1;
            }
        }
    }
    
    // Parameters xG, r where r = v - xc, and vG.
    // Verify that vG = rG + xcG!
    function verifyZKP(uint[2] xG, uint r, uint[3] vG) returns (bool){
      uint[2] memory G;
      G[0] = Gx;
      G[1] = Gy;

      // Check both keys are on the curve.
      if(!Secp256k1_noconflict.isPubKey(xG) || !Secp256k1_noconflict.isPubKey(vG)) {
        return false; //Must be on the curve!
      }

      // Get c = H(g, g^{x}, g^{v});
      bytes32 b_c = sha256(msg.sender, Gx, Gy, xG, vG);
      uint c = uint(b_c);

      // Get g^{r}, and g^{xc}
      uint[3] memory rG = Secp256k1_noconflict._mul(r, G);
      uint[3] memory xcG = Secp256k1_noconflict._mul(c, xG);

      // Add both points together
      uint[3] memory rGxcG = Secp256k1_noconflict._add(rG,xcG);

      // Convert to Affine Co-ordinates
      ECCMath_noconflict.toZ1(rGxcG, pp);

      // Verify. Do they match?
      if(rGxcG[0] == vG[0] && rGxcG[1] == vG[1]) {
         return true;
      } else {
         return false;
      }
  }

    //======================= submit vote ===========================================
    //CodeCredit: @Patrick McCorry
    function submitVote(uint[2] y, uint _vr, string _candidateName)  {
        /*
        // HARD DEADLINE
        if(block.timestamp > endVoting) {
            return;
        }
        */
   
        uint c = addressid[msg.sender];
        // Make sure the sender is registered
        if(registered[msg.sender]) {  
            for (uint i = 0; i < candidates.length; i++){
                if (keccak256(candidates[i].name) == keccak256(_candidateName)) {
                    if (_vr == 1){
                        candidates[i].voteReceived +=1;
                    }
                }
            }
            voters[c].vote[0] = y[0];
            voters[c].vote[1] = y[1];
            votecast[msg.sender] = true;
            voters[c].voted += 1;
            totalvoted += 1;
        }
  }
  
  //===================== compute Tally ===============================================
   //CodeCredit @Patrick McCorry
   //Modifications:
   // (1) added the "onlyOwner" modifier to allow the EA only to call this function
   // (2) run the internal computations for the number of candaidates
   
    function computeTally() onlyOwner {
        uint[3] memory temp;
        uint[2] memory vote;
        bool voted;
        uint totalNCountedVote;
        uint[2] memory idxCount;
        idxCount[0] = 0;
        idxCount[1] = 0;


     for (uint cidx = 0; cidx < candidates.length; cidx++) {    
        // Sum all votes
        totalCountedVote = candidates[cidx].voteReceived;
        for(uint i=0; i<totalregistered; i++) {
            // Confirm all votes have been cast...
            if(!votecast[voters[i].addr] && voters[i].voted < candidates.length) {
                throw;
            }
            
            totalNCountedVote = totalregistered - candidates[cidx].voteReceived;
            vote = voters[i].vote;

            if(i==0) {
                temp[0] = vote[0];
                temp[1] = vote[1];
                temp[2] = 1;
            } else {
             Secp256k1_noconflict._addMixedM(temp, vote);
            }
        }
      
        // If there are no votes... then 
        if(temp[0] == 0) {
            finaltally[0] = 0;
            finaltally[1] = 0;
            return;
        } else {
            ECCMath_noconflict.toZ1(temp,pp);
            uint[3] memory tempG;
            tempG[0] = G[0];
            tempG[1] = G[1];
            tempG[2] = 1;

            // Start adding 'G' and looking for a match
            for(i=1; i<=totalregistered; i++) {
                Secp256k1_noconflict._addMixedM(tempG, G);
                ECCMath_noconflict.toZ1(tempG,pp);
                finaltally[0] = totalNCountedVote;
                finaltally[1] = totalCountedVote;
            }
         }
        //candidate i's total "yes"
        candidates[cidx].voteReceived = finaltally[1];
        if (candidates[cidx].voteReceived > finaltally[0]){
            candidates[cidx].result = "winner";
        }else{
            candidates[cidx].result = "lost";
        }
      } 
    }
    
    //---------------- get Result of candidate ------------------------------------------
    //@group5
    string public Res; 
    function getResult(uint _candidate) returns (string) {
    Res = candidates[_candidate].result;
       return Res;
    } 
    
    //====================== Voter's only part =============================================
       
    //------------------- yes vote --------------------------
    //CodeCredit @Patrick McCorry
    function yes(uint[2] yG, uint x, string _candidateName) {
        uint[3] memory res;
        res = create1outof2ZKPYesVote(yG, x);
        uint[2] memory y = [res[0], res[1]];
        submitVote (y, res[2], _candidateName); 
    }
    
    
    //CodeCredit @Patrick McCorry
    function create1outof2ZKPYesVote(uint[2] yG,  uint x) returns (uint[3] res) {
      uint[3] memory temp1 = Secp256k1_noconflict._mul(x,yG);
      uint temp = 1;
      temp1 [2] = temp;
      Secp256k1_noconflict._addMixedM(temp1,G);
      ECCMath_noconflict.toZ1(temp1, pp);
      res[0] = temp1[0];
      res[1] = temp1[1];
      res[2] = temp1[2];
    }
    
    
    //-------------------------- no vote ------------------------------------------
    //CodeCredit @Patrick McCorry
    function no(uint[2] yG, uint x, string _candidateName) {
        uint[3] memory res;
        res = create1outof2ZKPNoVote(yG, x);
        uint[2] memory y = [res[0], res[1]];
        submitVote (y, res[2], _candidateName); 
    }
    
    //CodeCredit @Patrick McCorry
    function create1outof2ZKPNoVote(uint[2] yG,  uint x) returns (uint[3] res){
      uint[3] memory temp1 = Secp256k1_noconflict._mul(x,yG);
      ECCMath_noconflict.toZ1(temp1, pp);
      uint temp = 0;
      temp1 [2] = temp;
      res[0] = temp1[0];
      res[1] = temp1[1];
      res[2] = temp1[2];
    }
   //------------------------------------------
    
    

}

pragma solidity ^0.8.10;

contract Blockchain_edge {
  address public owner = msg.sender;
  address public counterparty;
  uint public currentBid;
  string public ipfs_job_Url;
  string public ipfs_output_Url;
  uint public constant MinEscrowFromComputeNode = 1 ether;
  uint public computeNodeEscrow = 0;
  uint public constant MinEscrowFromCounterparty = 1 ether;
  uint public counterpartyEscrow = 0;
  uint constant Timeout = 60 seconds;
  uint constant Penalty = 0.5 ether;
  uint public currentJobStartTime;
  uint public currentJobEndTime;

  enum Availablity {
    Unavailable,
    Available,
    Pending,
    Computing,
    Completed
  }
  Availablity public state = Availablity.Unavailable;


  constructor() public {
  }

  modifier onlyBy(address _address)
  {
    require(msg.sender == _address, 'Sender not authorized');
    _;
  }

  modifier onlyAfter(uint _time) {
    require(block.timestamp >= _time, 'Function called too early.');
    _;
  }

  modifier atState(Availablity _state)
  {
    require(state == _state, 'Not in proper state');
    _;
  }

  function setAvailable(uint bid) public payable
    onlyBy(owner)
    atState(Availablity.Unavailable)
  {
    computeNodeEscrow += msg.value;
    require(
      computeNodeEscrow >= MinEscrowFromComputeNode, 
      'Insufficient balance for Compute Node'
    );

    if (computeNodeEscrow > MinEscrowFromComputeNode) {
       payable(msg.sender).transfer(computeNodeEscrow - MinEscrowFromComputeNode);
      computeNodeEscrow = MinEscrowFromComputeNode;
    }

    currentBid = bid;
    state = Availablity.Available;
    
  }

  function acceptBid(string memory url) public payable
    atState(Availablity.Available)
  {
    counterpartyEscrow += msg.value;
    require(
      counterpartyEscrow >= MinEscrowFromCounterparty, 
      'Insufficient balance for Counterparty'
    );

    counterparty = msg.sender;
    ipfs_job_Url = url;
    state = Availablity.Pending;
    
  }

  function jobRejected() public
    onlyBy(owner)
    atState(Availablity.Pending)
  {
    refundCounterparty();
    counterparty = address(0);
    state = Availablity.Available;
    
  }

  function jobAccepted() public
    onlyBy(owner)
    atState(Availablity.Pending)
  {
    currentJobStartTime = block.timestamp;
    state = Availablity.Computing;
   
  }

  function jobCompleted(string memory url) public
    onlyBy(owner)
    atState(Availablity.Computing)
  {
    currentJobEndTime = block.timestamp;
    ipfs_output_Url = url;

    state = Availablity.Completed;
    
  }

  function jobTimedOut() public
    atState(Availablity.Computing)
    onlyAfter(currentJobStartTime + Timeout)
  {
    refundCounterparty();
    counterparty = address(0);
    state = Availablity.Unavailable;
   
  }

  function resultVerified() public
    onlyBy(counterparty)
    atState(Availablity.Completed)
  {
    chargeCounterparty();
    refundCounterparty();
    counterparty = address(0);

    state = Availablity.Unavailable;
   
  }

  function resultTimedOut() public
    atState(Availablity.Completed)
    onlyAfter(currentJobEndTime + Timeout)
  {
    chargeCounterparty();
    refundCounterparty();
    counterparty = address(0);

    state = Availablity.Unavailable;
    
  }

  function resultRejected() public
    onlyBy(counterparty)
    atState(Availablity.Completed)
  {
    refundCounterparty();

    payable(counterparty).transfer(Penalty);
    computeNodeEscrow -= Penalty;

    counterparty = address(0);
    state = Availablity.Unavailable;
  
  }

  function chargeCounterparty() private
  {
    uint cost = (currentJobEndTime - currentJobStartTime) * currentBid;
    if (cost > counterpartyEscrow) {
      cost = counterpartyEscrow;
    }

    payable(owner).transfer(cost);
    counterpartyEscrow -= cost;
  }

  function refundCounterparty() private
  {
    assert(counterparty != address(0));

    if (counterpartyEscrow > 0) {
      payable(counterparty).transfer(counterpartyEscrow);
    }
    counterpartyEscrow = 0;
  }

}
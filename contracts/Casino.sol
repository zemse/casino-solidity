//pragma solidity 0.4.20; ///compiler version
pragma solidity ^0.5.0; ///compiler version

contract Casino {
  address public owner;
  uint256 public minimumBet;
  uint256 public totalBet;
  uint256 public numberOfBets;
  uint256 public maxAmountsOfBets = 100;
  address[] public players;

  struct Player {
    uint256 amountBet;
    uint256 numberSelected;
  }

  mapping (address => Player) public playerInfo;

  //Fallback function in case someone sends ether to the contract so it doesn't get lost and to increase the treasury of this contract that will be distributed in each game
  function() external payable {}
  //This will allow you to save the ether you send to the contract. Otherwise it would be rejected.

  constructor(uint256 _minimumBet) public { // _ underscore is used before the parameters
    owner = msg.sender;
    if(_minimumBet != 0) minimumBet = _minimumBet;
  }

  function kill() public {
    if(msg.sender == owner) selfdestruct(address(uint160(owner)));
  }

  function checkPlayerExists(address _playerAddress) public view returns(bool) {
    for(uint256 i = 0; i < players.length; i++) {
      if(players[i] == _playerAddress) return true;
    }
    return false;
  }

  function resetData() internal {
     players.length = 0; // Delete all the players array
     totalBet = 0;
     numberOfBets = 0;
  }



  function distributePrize(uint256 _numberGenerated) internal {
    address[100] memory winners; //temporary array created in memory with fixed size
    uint256 count = 0;
    for(uint256 i = 0; i < players.length; i++) {
      address playerAddress = players[i];
      if(playerInfo[playerAddress].numberSelected == _numberGenerated) {
        winners[count] = playerAddress;
        count++;
      }
      delete playerInfo[playerAddress];
    }
    players.length = 0; //deletes the players in the array
    uint256 winnerEtherAmount = totalBet/count; //what if count is zero.
    for(uint256 i = 0; i < count; i++) {
      address payable payTo = address(uint160(winners[i]));
      if(payTo != address(0)) { //checking that address is not empty due to error
        payTo.transfer(winnerEtherAmount);
      }
    }
    resetData();
  }

  function generateWinnerNumber() internal {
    uint256 numberGenerated = (block.number+now)%10 + 1;
    distributePrize(uint256(numberGenerated));
  }


  //betting function for number from 1 to 10
  function bet(uint256 _numberSelected) public payable { //payable is a modifier,, it’s used to indicate that this function can receive ether when you execute it.
    require(!checkPlayerExists(msg.sender)); //checks whether msg.sender exists in players array
    require(_numberSelected >= 1 && _numberSelected <= 10);
    require(msg.value >= minimumBet);
    playerInfo[msg.sender].amountBet = msg.value;
    playerInfo[msg.sender].numberSelected = _numberSelected;
    numberOfBets++;
    players.push(msg.sender);
    totalBet += msg.value;
    if (numberOfBets >= maxAmountsOfBets) generateWinnerNumber();
  }
}

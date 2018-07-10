pragma solidity 0.4.24;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract BonusHolder is Pausable {
  using SafeMath for uint256;
  uint public withdrawTime;
  ERC20 public token;

  mapping(address => uint) public bonus;


  modifier afterClose() {
    if(now < withdrawTime) {
      revert();
    } else {
      _;
    }
  }


  constructor(ERC20 _token, uint _withdrawTime) {
    require(_withdrawTime > 0);
    require(_withdrawTime > now);
    withdrawTime = _withdrawTime;
    token = _token;
  }

  function addBonus(address beneficiary, uint tokenAmount) internal {
    require(now < withdrawTime);
    bonus[beneficiary].add(tokenAmount);
  }


  function withdrawToken() public afterClose whenNotPaused {
    require(bonus[msg.sender] > 0);
    uint tokenAmount = bonus[msg.sender];
    bonus[msg.sender] = 0;
    token.transfer(msg.sender, tokenAmount);
  }

}

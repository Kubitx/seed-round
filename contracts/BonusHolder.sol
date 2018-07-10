pragma solidity 0.4.24;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Whitelist.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract BonusHolder is Whitelist, Pausable {
  using SafeMath for uint256;
  ERC20 public token;
  uint public withdrawTime;
  address public controller;

  mapping(address => uint) bonus;

  modifier onlyController() {
    if(msg.sender != controller) {
      revert();
    } else {
      _;
    }
  }

  modifier afterClose() {
    if(now < withdrawTime) {
      revert();
    } else {
      _;
    }
  }

  modifier beforeClose() {
    if(now > withdrawTime) {
      revert();
    } else {
      _;
    }
  }


  constructor(ERC20 _token, uint _withdrawTime) {
    require(_withdrawTime > 0);
    require(_withdrawTime > now);
    token = _token;
    withdrawTime = _withdrawTime;
    controller = msg.sender;
    super.addAddressToWhitelist(msg.sender);
  }

  function addBonus(address beneficiary, uint tokenAmount) public onlyController beforeClose whenNotPaused {
    require(now < withdrawTime);
    bonus[beneficiary].add(tokenAmount);
  }

  function changeController(address newController) public onlyWhitelisted whenNotPaused {
    controller = newController;
  }

  function withdrawToken() public afterClose whenNotPaused {
    require(bonus[msg.sender] > 0);
    uint tokenAmount = bonus[msg.sender];
    bonus[msg.sender] = 0;
    token.transfer(msg.sender, tokenAmount);
  }

}

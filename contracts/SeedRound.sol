pragma solidity 0.4.24;
import "openzeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Whitelist.sol";
import "openzeppelin-solidity/contracts/ownership/CanReclaimToken.sol";
import "./BonusHolder.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract SeedRound is CappedCrowdsale, FinalizableCrowdsale, Whitelist, Pausable, CanReclaimToken {

  uint public minContribution;
  uint public bonus;
  BonusHolder public holder;

  constructor(uint256 _openingTime, uint256 _closingTime, uint _minContribution,uint256 _bonus, uint256 _rate, uint256 _cap, address _wallet, ERC20 _token, BonusHolder _holder)
  CappedCrowdsale(_cap) TimedCrowdsale(_openingTime, _closingTime) Crowdsale(_rate, _wallet, _token) {
    require(_minContribution > 0);
    require(_bonus > 0);
    minContribution = _minContribution;
    bonus = _bonus;
    holder = _holder;
    super.addAddressToWhitelist(msg.sender);
  }

  function _forwardFunds() internal {

  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal whenNotPaused {
    require(_weiAmount >= minContribution);
    require(holder.controller() == address(this));
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

  function changeMinContribution(uint _minContribution) public onlyWhitelisted {
    require(_minContribution > 0);
    minContribution = _minContribution;
  }

  function changeBonus(uint _bonus) public onlyWhitelisted {
    require(_bonus > 0);
    bonus = _bonus;
  }

  function withdrawFunds(uint amount) public onlyWhitelisted {
    require(address(this).balance >= amount);
    msg.sender.transfer(amount);
  }

  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    uint bonusTokens = _tokenAmount.mul(bonus).div(100);
    token.transfer(holder, bonusTokens);
    holder.addBonus(_beneficiary, bonusTokens);
    super._deliverTokens(_beneficiary, _tokenAmount);
  }

  function finalization() internal {
    // do we need this changeController ?
    holder.changeController(address(0));
    token.transfer(msg.sender, token.balanceOf(this));
  }
}

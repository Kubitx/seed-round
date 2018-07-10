pragma solidity 0.4.24;
import "openzeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Whitelist.sol";
import "openzeppelin-solidity/contracts/ownership/CanReclaimToken.sol";
import "./BonusHolder.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract SeedRound is CappedCrowdsale, FinalizableCrowdsale, Whitelist, Pausable, CanReclaimToken, BonusHolder {

  uint public minContribution;
  uint public bonusRate;

  constructor(uint256 _openingTime, uint256 _closingTime, uint _minContribution,uint256 _bonusRate, uint256 _rate, uint256 _cap, address _wallet, ERC20 _token, uint _bonusWithdrawTime)
  CappedCrowdsale(_cap) TimedCrowdsale(_openingTime, _closingTime) Crowdsale(_rate, _wallet, _token) BonusHolder(_token, _bonusWithdrawTime) {
    require(_minContribution > 0);
    require(_bonusRate > 0);
    minContribution = _minContribution;
    bonusRate = _bonusRate;
    super.addAddressToWhitelist(msg.sender);
  }

  function _forwardFunds() internal {

  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal whenNotPaused {
    require(_weiAmount >= minContribution);
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

  function changeMinContribution(uint _minContribution) public onlyWhitelisted whenNotPaused {
    require(_minContribution > 0);
    minContribution = _minContribution;
  }

  function changeBonusRate(uint _bonusRate) public onlyWhitelisted whenNotPaused {
    require(_bonusRate > 0);
    bonusRate = _bonusRate;
  }

  function withdrawFunds(uint amount) public onlyWhitelisted whenNotPaused {
    require(address(this).balance >= amount);
    msg.sender.transfer(amount);
  }

  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    uint bonusTokens = _tokenAmount.mul(bonusRate).div(100);
    super.addBonus(_beneficiary, bonusTokens);
    super._deliverTokens(_beneficiary, _tokenAmount);
  }

  function finalization() internal {
    token.transfer(msg.sender, token.balanceOf(this));
  }
}

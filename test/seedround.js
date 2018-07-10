let SeedRound = artifacts.require("./SeedRound.sol");
let Token = artifacts.require('BasicTokenMock');
import ether  from './helpers/ether';
import latestTime from './helpers/latestTime'
const EVMRevert = require('./helpers/EVMRevert.js')
import BigNumber  from 'bignumber.js';
import {increaseTimeTo, duration} from './helpers/increaseTime'


require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

contract('SeedRound', async function(accounts) {

  describe('Seed Round Construction', async () => {
    it('initializes all the parameters', async () => {
      const token = await Token.new(accounts[0], ether(10000000));
      const openingTime = latestTime() + duration.minutes(2);
      const closingTime = openingTime + duration.days(10);
      const minContribution = ether(1);
      const bonusRate = 65;
      const rate = 9898;
      const cap = ether(10);
      const wallet = accounts[5];
      const bonusWTime = closingTime + duration.days(10);
      const seed = await SeedRound.new(openingTime, closingTime, minContribution, bonusRate, rate, cap, wallet, token.address, bonusWTime);
      assert((await seed.openingTime()).toString() == openingTime.toString());
      assert((await seed.closingTime()).toString() == closingTime.toString());
      (await seed.minContribution()).should.be.bignumber.equal(minContribution);
      assert((await seed.rate()).toString() == rate.toString());
      assert((await seed.bonusRate()).toString() == bonusRate.toString());
      (await seed.cap()).should.be.bignumber.equal(cap);
      assert((await seed.withdrawTime()).toString() == bonusWTime.toString());
      assert((await seed.token()) == token.address);
    });
  });
  describe('Seed Round Contribution', async () => {
    let token;
    let seedRound;
    beforeEach(async () => {
      let totalSupply =  ether(10000000);
      token = await Token.new(accounts[0], totalSupply);
      const openingTime = latestTime() + duration.minutes(2);
      const closingTime = openingTime + duration.days(10);
      const minContribution = ether(1);
      const bonusRate = 65;
      const rate = 9898;
      const cap = ether(2.5);
      const wallet = accounts[5];
      const bonusWTime = closingTime + duration.days(10);
      seedRound = await SeedRound.new(openingTime, closingTime, minContribution, bonusRate, rate, cap, wallet, token.address, bonusWTime);
      await token.transfer(seedRound.address, totalSupply);

    })

    it('should throw if the the crowdsale has not opened', async () => {
      await seedRound.sendTransaction({ from: accounts[0], value: ether(1) })
      .should.be.rejectedWith(EVMRevert);

    });
    it('should throw if the the crowdsale has passed closing', async () => {
      await increaseTimeTo((await seedRound.closingTime()).toNumber() + 10);
      await seedRound.sendTransaction({ from: accounts[0], value: ether(1) })
      .should.be.rejectedWith(EVMRevert);
    });

    it('should reject below min contribution', async () => {
      await increaseTimeTo((await seedRound.openingTime()).toNumber() + 10);
      await seedRound.sendTransaction({ from: accounts[0], value: ether(0.1) })
      .should.be.rejectedWith(EVMRevert);
    });
    //
    it('should accept contribution', async () => {
      await increaseTimeTo((await seedRound.openingTime()).toNumber() + 10);
      await seedRound.sendTransaction({ from: accounts[2], value: ether(2) })
      .should.be.fulfilled;
      let balance = await token.balanceOf(accounts[2]);
      let rate = (await seedRound.rate()).toNumber();
      let bonusRate = (await seedRound.bonusRate()).toNumber();
      let expectedBalance = ether(2*rate);
      balance.should.be.bignumber.equal(expectedBalance);
      let totalContribution = web3.eth.getBalance(seedRound.address);
      totalContribution.should.be.bignumber.equal(ether(2));
      let expectedBonus = ether(2*rate*bonusRate).div(100);
      let bonus = await seedRound.bonus(accounts[2]);
      bonus.should.be.bignumber.equal(expectedBonus);
    });
    //
    it('should rejected if the cap has been reached', async () => {
      await increaseTimeTo((await seedRound.openingTime()).toNumber() + 10);
      await seedRound.sendTransaction({ from: accounts[2], value: ether(2.5) }).should
      .be.fulfilled;
      await seedRound.sendTransaction({ from: accounts[2], value: ether(2.5) }).should
      .be.rejectedWith(EVMRevert);
      let balance = web3.eth.getBalance(seedRound.address);
      balance.should.be.bignumber.equal(ether(2.5));
    });
    //
    it('withdrawTokens after withdrawTime', async () => {
      await increaseTimeTo((await seedRound.openingTime()).toNumber() + 10);
      await seedRound.sendTransaction({ from: accounts[3], value: ether(2) });
      let bonus = await seedRound.bonus(accounts[3]);

      await seedRound.withdrawToken({from: accounts[3]})
      .should.be.rejectedWith(EVMRevert);

      await seedRound.withdrawToken({from: accounts[1]})
      .should.be.rejectedWith(EVMRevert);

      await increaseTimeTo((await seedRound.withdrawTime()).toNumber() + 10);
      let balance = await token.balanceOf(accounts[3]);
      await seedRound.withdrawToken({from: accounts[3]})
      .should.be.fulfilled;
      let expectedBalance = balance.add(bonus);
      (await token.balanceOf(accounts[3])).should.be.bignumber.equal(expectedBalance);
    });
    //
    it('withdraw funds can be called only by onlyWhitelisted', async () => {
      await increaseTimeTo((await seedRound.openingTime()).toNumber() + 10);
      await seedRound.sendTransaction({ from: accounts[3], value: ether(2) });
      await seedRound.addAddressToWhitelist(accounts[1]);
      let amount = ether(1);
      await seedRound.withdrawFunds(amount, {from: accounts[3]})
      .should.be.rejectedWith(EVMRevert);
      await seedRound.withdrawFunds(amount, {from: accounts[1]})
      .should.be.not.rejectedWith(EVMRevert);
      let seedRoundBalance = web3.eth.getBalance(seedRound.address);
      seedRoundBalance.should.be.bignumber.equal(ether(1));
    });

    it('contributions are not accepted when paused', async () => {
      await increaseTimeTo((await seedRound.openingTime()).toNumber() + 10);
      await seedRound.pause();
      await seedRound.sendTransaction({ from: accounts[3], value: ether(2) })
      .should.be.rejectedWith(EVMRevert);
    });

    it('contributions after bonus change', async () => {
      await increaseTimeTo((await seedRound.openingTime()).toNumber() + 10);
      await seedRound.changeBonusRate(50);
      await seedRound.sendTransaction({ from: accounts[4], value: ether(2) })
      let rate = (await seedRound.rate()).toNumber();
      let bonusRate = (await seedRound.bonusRate()).toNumber();
      let expectedBonus = ether(2*rate*bonusRate).div(100);
      let bonus = await seedRound.bonus(accounts[4]);
      bonus.should.be.bignumber.equal(expectedBonus);

    })

    it('change rate works', async () => {
      let rate = 100;
      await seedRound.changeTokenRate(rate);
      assert((await seedRound.rate()).toNumber() == rate);
    })
  });
});

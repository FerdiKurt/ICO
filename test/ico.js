// todo: purchase size and price logic is wrong
// todo: examine this and create correct logic

const { expectRevert, time } = require('@openzeppelin/test-helpers');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');

const ICO = artifacts.require('ICO.sol');
const Token = artifacts.require('ERC20Token.sol');

function toBN(arg) {
    return web3.utils.toBN(arg)
}

function toWEI(arg) {
    return web3.utils.toWei(arg)
}

contract('ICO', accounts => {
    let ico;
    let token;

    const name = 'My Token';
    const symbol = 'TKN'; 
    const decimals = 18;
    const initialBalance = toBN(toWEI('1000'));

    const admin = accounts[0]
    const duration = 100;
    const pricePerUnit = 2;
    const availableTokens = toWEI('30');
    const minPurchase = toWEI('1'); 
    const maxPurchase = toWEI('10');

    beforeEach(async () => {
        ico = await ICO.new(name, symbol, decimals, initialBalance); 
        const tokenAddress = await ico.token();
        token = await Token.at(tokenAddress); 
    });

    it('should create an erc20 token', async () => {
        const _name = await token.name()
        const _symbol = await token.symbol()
        const _decimals = await token.decimals()
        const _totalSupply = await token.totalSupply()

        assert(_name == name)
        assert(_symbol == _symbol)
        assert(_decimals == decimals)
        assert(_totalSupply.eq(initialBalance))        
    });

    //test a bit flaky because of testing of `expectedEnd`. 
    //you can comment out the assertion on this variable to fix this
    it('should start the ICO', async () => { 
        const start = parseInt((new Date()).getTime() / 1000);
        time.increaseTo(start);
        await ico.start(duration, pricePerUnit, availableTokens, minPurchase, maxPurchase, { from: admin }); 
    
        const expectedEnd = start + duration;
        const end = await ico.endOfICO();
        const actualPrice = await ico.pricePerUnit();
        const actualAvailableTokens = await ico.availableTokens();
        const actualMinPurchase = await ico.minPurchase();
        const actualMaxPurchase = await ico.maxPurchase();

        assert(end.eq(toBN(expectedEnd)))
        assert(actualPrice.eq(toBN(pricePerUnit)))
        assert(actualAvailableTokens.eq(toBN(availableTokens)))
        assert(actualMinPurchase.eq(toBN(minPurchase)))
        assert(actualMaxPurchase.eq(toBN(maxPurchase)))
    });

    it('should NOT start the ICO with invalid amount', async () => {
        const invalidAmount = toBN(toWEI('10000'))
        await expectRevert(
            ico.start(duration, pricePerUnit, invalidAmount, minPurchase, maxPurchase, { from: admin }),
            'Invalid amount provided!'
        )
    });

    it('should NOT start the ICO with ZERO duration', async () => {
        await expectRevert(
            ico.start(0, pricePerUnit, availableTokens, minPurchase, maxPurchase, { from: admin }),
            'Invalid duration provided!'
        )
    });

    it('should NOT start the ICO with invalid price', async () => {
        await expectRevert(
            ico.start(duration, 0, availableTokens, minPurchase, maxPurchase, { from: admin }),
            'Invalid price proided!'
        )
    });

    it('should NOT start the ICO with invalid min purchase', async () => {
        await expectRevert(
            ico.start(duration, pricePerUnit, availableTokens, 0, maxPurchase, { from: admin }),
            'Min must be greater than 0!'
        )
    });

    it('should NOT start the ICO with invalid max purchase', async () => {
        const maxPurchase = toWEI('800')
        await expectRevert(
            ico.start(duration, pricePerUnit, availableTokens, minPurchase, maxPurchase, { from: admin }),
            'Invalid max purchase provided!'
        )
    });

    context('Sale started', () => {
        // beforeEach(async() => {
        //     const start = parseInt((new Date()).getTime() / 1000);
        //     time.increaseTo(start);
        //     ico.start(duration, pricePerUnit, availableTokens, minPurchase, maxPurchase, { from: admin }); 
        // });

        // it('should NOT let non-investors buy', async () => {
        //     await expectRevert(
        //         ico.buy({ from: accounts[1], value: toWEI('10')}),
        //         'Only investors!'
        //     )
        // });

        // it('should NOT buy non-multiple of price', async () => {
        //     await ico.addToWhitelist(accounts[1], { from: admin })
        //     const value = toBN(toWEI('1'))
        //     .add(toBN(1));
        //     await expectRevert(
        //         ico.buy({ from: accounts[1], value }),
        //         'Should be multiple of price!'
        //     )
        // });

        // it('should NOT buy if not between min and max purchase', async () => {
        //     await ico.addToWhitelist(accounts[1], { from: admin })
        //     await expectRevert(
        //         ico.buy({ from: accounts[1], value: toWEI('20')}),
        //         'invalid msg.value() provided!'
        //     )
        // });

        // it('should NOT buy if not enough tokens left', async () => {
        //     await ico.addToWhitelist(accounts[1]);
        //     await ico.buy({from: accounts[1], value: toWEI('10')})
        //     await ico.buy({from: accounts[1], value: toWEI('10')})
        //     await ico.buy({from: accounts[1], value: toWEI('4')})

        //     await expectRevert(
        //         ico.buy({from: accounts[1], value: toWEI('10')}),
        //         'Not enough tokens for sale!'
        //     );
        // });

        // it.only(
        //     'full ico process: investors buy, admin release and withdraw', 
        //     async () => {
        //     const [investor1, investor2] = [accounts[1], accounts[2]];
        //     const [amount1, amount2] = [
        //       web3.utils.toBN(web3.utils.toWei('1')),
        //       web3.utils.toBN(web3.utils.toWei('10')),
        //     ];
        //     await ico.addToWhitelist(investor1);
        //     await ico.addToWhitelist(investor2);
        //     await ico.buy({from: investor1, value: amount1}); 
        //     await ico.buy({from: investor2, value: amount2}); 
      
        //     await expectRevert(
        //       ico.release({from: investor1}),
        //       'Only admin!'
        //     );
      
        //     await expectRevert(
        //       ico.release(),
        //       'ICO still active!'
        //     );
      
        //     await expectRevert(
        //       ico.withdraw(accounts[9], 10),
        //       'ICO still active!'
        //     );
      
        //     // Admin release tokens to investors
        //     const start = parseInt((new Date()).getTime() / 1000);
        //     time.increaseTo(start + duration + 10);
        //     await ico.release({ from: admin });

        //     const balance1 = await token.balanceOf(investor1);
        //     const balance2 = await token.balanceOf(investor2);
        //     assert(balance1.eq(amount1.mul(web3.utils.toBN(pricePerUnit))));
        //     assert(balance2.eq(amount2.mul(web3.utils.toBN(pricePerUnit))));
      
        //     await expectRevert(
        //       ico.withdraw(accounts[9], 10, {from: investor1}),
        //       'Only admin!'
        //     );
      
        //     // Admin withdraw ether that was sent to the ico
        //     const balanceContract = web3.utils.toBN(
        //       await web3.eth.getBalance(token.address)
        //     );
        //     const balanceBefore = web3.utils.toBN(
        //       await web3.eth.getBalance(accounts[9])
        //     );
        //     await ico.withdraw(accounts[9], balanceContract);
        //     const balanceAfter = web3.utils.toBN(
        //       await web3.eth.getBalance(accounts[9])
        //     );
        //     assert(balanceAfter.sub(balanceBefore).eq(balanceContract));
        //   });
    });
});

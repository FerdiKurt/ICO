const { expectRevert, time } = require('@openzeppelin/test-helpers');

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
    let tokenContract;

    const name = 'My Token';
    const symbol = 'TKN'; 
    const decimals = 18;
    const initialBalance = 1000

    const admin = accounts[0]
    const duration = 100;
    const price = 2;
    const available = 500
    const allowedTokens = 10
    const percentage = 2
 
  
    beforeEach(async () => {
        ico = await ICO.new(name, symbol, decimals, initialBalance); 
        const tokenAddress = await ico.token();
        tokenContract = await Token.at(tokenAddress); 
    });

    it('should create an erc20 token', async () => {
        const _name = await tokenContract.name()
        const _symbol = await tokenContract.symbol()
        const _decimals = await tokenContract.decimals()
        const _totalSupply = await tokenContract.totalSupply()

        assert(_name == name)
        assert(_symbol == _symbol)
        assert(_decimals == decimals)
        assert(_totalSupply == initialBalance)        
    });

    it('should start the ICO', async () => { 
        const start = parseInt((new Date()).getTime() / 1000)
        time.increaseTo(start)
        await ico.start(duration, price, available, allowedTokens, percentage, { from: admin })
    
        const tokenPrice = await ico.pricePerToken()
        const purchaseLimit = await ico.purchaseLimit()
        const actualAvailableTokens = await ico.availableTokens()
        const rate = await ico.percentage()
       
        assert(tokenPrice.eq(toBN(price)))
        assert(purchaseLimit.eq(toBN(allowedTokens)))
        assert(actualAvailableTokens.eq(toBN(available)))
        assert(rate.toNumber() == percentage)
    });

    it('should NOT start the ICO ', async () => {
        const invalidAmount = toWEI('1001')
        const invalidLimit = toWEI('11')

        await expectRevert(
            ico.start(duration, price, invalidAmount, allowedTokens, percentage, { from: admin }),
            'Invalid amount provided!'
        )
        
        await expectRevert(
            ico.start(0, price, available, allowedTokens, percentage, { from: admin }),
            'Invalid duration provided!'
        )

        await expectRevert(
            ico.start(duration, 0, available, allowedTokens, percentage, { from: admin }),
            'Invalid price provided!'
        )

        await expectRevert(
            ico.start(duration, price, available, invalidLimit, percentage, { from: admin }),
            'Invalid purchase limit provided!'
        )

        await expectRevert(
            ico.start(duration, price, available, allowedTokens, 51, { from: admin }),
            'Invalid percentage rate is given!'
        )
    });

    context('Sale started', () => {
        beforeEach(async() => {
            const start = parseInt((new Date()).getTime() / 1000);
            time.increaseTo(start);
            ico.start(duration, price, available, 250, 50, { from: admin }); 
        });

        it('should NOT let non-investors buy', async () => {
            await expectRevert(
                ico.buy(5, { from: accounts[1], value: 10 }),
                'Only investors!'
            )
        });

        it('should NOT buy if not enough ether provided', async () => {
            await ico.addToWhitelist(accounts[1], { from: admin })

            await expectRevert(
                ico.buy(5, { from: accounts[1], value: 9 }),
                'Not enough ether provided!'
            )
        });

        it('should NOT buy if not valid token amount provided', async () => {
            await ico.addToWhitelist(accounts[1], { from: admin })

            await expectRevert(
                ico.buy(251, { from: accounts[1], value: 502 }),
                'Invalid token amount!'
            )
        });

        it('should buy tokens', async () => {
            await ico.addToWhitelist(accounts[1], { from: admin });
            await ico.buy(250, {from: accounts[1], value: 500 })
           
            let remainingTokens = await ico.availableTokens()
            assert.equal(remainingTokens.toNumber(), 250)

            await ico.buy(240, {from: accounts[1], value: 480 })
            remainingTokens = await ico.availableTokens()

            assert.equal(remainingTokens.toNumber(), 10)

            await ico.addToWhitelist(accounts[2], { from: admin })

            await expectRevert(
                ico.buy(20, { from: accounts[2], value: 40 }),
                'Not enough tokens for sale!'
            )
        });

        // full process lifecycle
        it.only('should show full lifecycle process correctly', async () => {
            const amountOfToken = await ico.availableTokens()
            assert.equal(amountOfToken.toNumber(), available)

            await expectRevert(
                ico.release( {from: admin }),
                'ICO still active!'
            )

            await expectRevert(
                ico.withdraw(accounts[9], 10, { from: admin }),
                'ICO still active!'
            )

            const [ investor1, investor2, investor3 ] = [ accounts[1], accounts[2], accounts[3] ]
            const [ amount1, amount2, amount3 ] = [ 250, 170, 40 ]

            await ico.addToWhitelist(investor1, { from: admin })
            await ico.addToWhitelist(investor2, { from: admin })
            await ico.addToWhitelist(investor3, { from: admin })
            
            await ico.buy(amount1, { from: investor1, value: 500 })
            await ico.buy(amount2, { from: investor2, value: 340 })
            await ico.buy(amount3, { from: investor3, value: 80 })
        
            // admin release tokens
            const start = parseInt((new Date()).getTime() / 1000);
            time.increase(start + duration + 101)

            await expectRevert(
                ico.release({ from: investor1 }),
                'Only admin!'
            )

            await ico.release({ from: admin });
            const balance1 = await tokenContract.balanceOf(investor1);
            const balance2 = await tokenContract.balanceOf(investor2);
            const balance3 = await tokenContract.balanceOf(investor3);
            assert(balance1.eq(toBN(250)))
            assert(balance2.eq(toBN(170)))
            assert(balance3.eq(toBN(40)))

            inactiveTokenAmount = await ico.availableTokens()
            assert.equal(inactiveTokenAmount.toNumber(), 40)
            
            // admin withdraws ether from contract
            await expectRevert(
                ico.withdraw(accounts[0], 10, { from: investor1 }),
                'Only admin!'
            )

           // Admin withdraw ether that was sent to the ico
            const balanceContract = toBN(await web3.eth.getBalance(ico.address));
            const balanceBefore = toBN(await web3.eth.getBalance(accounts[0]));

            const tx = await ico.withdraw(
                accounts[0], 
                balanceContract, 
                { from: admin, gasPrice: 1 }
            );

            const gasUsed = toBN(tx.receipt.gasUsed)
            const balanceAfter = toBN(await web3.eth.getBalance(accounts[0]));
            assert(balanceAfter.sub(balanceBefore).add(gasUsed).eq(balanceContract));

            await expectRevert(
                ico.withdraw(accounts[9], balanceContract, { from: admin}),
                'Invalid ether input!'
            )
        })
    })
})

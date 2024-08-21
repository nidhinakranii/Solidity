This smart contract is not live anywhere it's just for learning purposes.

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract TestToken {
    // Tokens in account
    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }

    // profits in account
    modifier onlyProfitHolders() {
        require(myDividends(true) > 0);
        _;
    }

    modifier OnlyAdmin() {
        address _customerAddress = msg.sender;
        require(administrators[keccak256(abi.encodePacked(_customerAddress))]);
        _;
    }

    modifier OnlyHoldingHolders() {
        address _customerAddress = msg.sender;
        require(administrators[keccak256(abi.encodePacked(_customerAddress))]);
        _;
    }

    /*--------------------------------
    =             EVENTS            =
    --------------------------------*/
    event onTESTTokenPurchase(
        address indexed customerAddress,
        uint256 incomingBNB,
        uint256 tokensMinted,
        address indexed experterredBy
    );

    event onTESTTokensell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 BNBEarned
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 BNBReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(address indexed customerAddress, uint256 BNBWithdrawn);

    event onClaim(
        address indexed _customerAddress,
        uint256 _HoldingBonus,
        uint256 timestamp
    );

    // ERC20
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    /*--------------------------------
    =           CONFIGURABLES        =
    --------------------------------*/

    string public name = "TEST";
    string public symbol = "TESTToken";
    uint8 public constant decimals = 18;
    uint8 internal constant dividendFee_ = 4;
    uint256 internal tokenPriceInitial_ = 0.00000001 ether;
    uint256 internal constant tokenPriceIncremental_ = 0.0000000001 ether;
    uint256 internal constant magnitude = 10**18;
    address administratorAddress; // Admin address
    // proof of stake
    uint256 public stakingRequirement = 1e18;

    /*--------------------------------
    =             DATASETS          =
    --------------------------------*/

    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) public expertBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal HoldingRewardTo_;
    mapping(address => uint256) public start_time;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    uint256 internal holding_Reward_amount;
    mapping(bytes32 => bool) internal administrators;

    /*--------------------------------
    =          PUBLIC FUNCTIONS      =
    --------------------------------*/

    /*
     * -- APPLICATION ENTRY POINTS --
     */
    function TEST(address _customerAddress, address _adminAddress) public {
        // add administrators here
        administrators[keccak256(abi.encodePacked(_customerAddress))] = true;
        administratorAddress = _adminAddress;
    }

    //  purchace token in buy
    function buy(address _expertedBy) public payable returns (bool) {
        uint256 amount = msg.value;
        purchaseTokens(amount, _expertedBy);

        return true;
    }

    function getToken() public payable returns (bool) {
        uint256 amount = msg.value;
        purchaseTokens(amount, 0x0000000000000000000000000000000000000000);

        return true;
    }

    function reinvest() public onlyProfitHolders {
        uint256 _dividends = myDividends(false); // retrieve expert bonus later in the code

        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

        // retrieve expert bonus
        _dividends += expertBalance_[_customerAddress];
        expertBalance_[_customerAddress] = 0;

        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends, address(0));

        // fire event
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    //  Alias of sell() and withdraw() for exit from TEST function
    function exit() public {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress]; // account of TESTToken
        if (_tokens > 0) sell(_tokens); // sell all TESTToken.
        withdraw(); // withdraw BNB
    }

    //  Withdraws all of the callers earnings in BNB.
    function withdraw() public onlyProfitHolders {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // get expert bonus

        if (block.timestamp >= start_time[_customerAddress]) {
            claim();
        }

        payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

        // add expert. bonus
        _dividends += expertBalance_[_customerAddress];
        expertBalance_[_customerAddress] = 0;

        // Transfer BNB Final call
        payable(_customerAddress).transfer(_dividends);
        // Event call
        emit onWithdraw(_customerAddress, _dividends);
    }

    //  Liquifies TESTToken to BNB.
    function sell(uint256 _amountOfTokens) public onlyTokenHolders {
        address _customerAddress = msg.sender;

        require(_amountOfTokens / 1e18 >= 1);

        if (block.timestamp >= start_time[_customerAddress]) {
            claim();
        }

        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _BNB = tokensToBNB_(_tokens);
        uint256 _dv = SafeMath.div(_BNB, 10);
        uint256 _taxedBNB = SafeMath.sub(_BNB, _dv);
        uint256 _dividends = SafeMath.div(_dv, 2);
        uint256 holding_reward = _dividends;
        uint256 _totalcustomertokens = tokenBalanceLedger_[_customerAddress];
        // burn the sold TESTToken
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(
            tokenBalanceLedger_[_customerAddress],
            _tokens
        );

        // update dividends tracker
        int256 _updatedPayouts = (int256)(
            profitPerShare_ * _tokens + (_taxedBNB * magnitude)
        );
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        uint256 _HoldingWithdraw = HoldingRewardTo_[_customerAddress];

        if (_HoldingWithdraw > 0) {
            uint256 _pertokenholding = (_HoldingWithdraw /
                _totalcustomertokens);
            uint256 _DeductBonus = (_pertokenholding * _tokens);
            HoldingRewardTo_[_customerAddress] -= _DeductBonus;
        }

        start_time[_customerAddress] = block.timestamp + 30 days;

        // dividing and holding_reward not to be infinite
        if (tokenSupply_ > 0) {
            profitPerShare_ = SafeMath.add(
                profitPerShare_,
                (_dividends * magnitude) / tokenSupply_
            );
            holding_Reward_amount = SafeMath.add(
                holding_Reward_amount,
                (holding_reward * magnitude) / tokenSupply_
            );
        }
        // event call
        emit onTESTTokensell(_customerAddress, _tokens, _taxedBNB);
    }

    // claim for the Account after 30 day
    function claim() internal onlyProfitHolders returns (bool) {
        address _customerAddress = msg.sender;

        // check the time of the end in 30 day
        require(block.timestamp >= start_time[_customerAddress]);
        require(tokenSupply_ > 0);

        uint256 _HoldingBonus = myHoldingBonus(_customerAddress); // count the acccount holding_reward
        if (_HoldingBonus > 0) // not to be less then zero
        {
            HoldingRewardTo_[_customerAddress] += (_HoldingBonus * magnitude);
            payable(_customerAddress).transfer(_HoldingBonus);
        }
        start_time[_customerAddress] = block.timestamp + 30 days;

        // event call
        emit onClaim(_customerAddress, _HoldingBonus, start_time[_customerAddress]);

        return true;
    }

    //  Transfer tokens from the Account to a new Receiver Account.
    //  10% fee deduction and added to the admin.

    function transfer(address _toAddress, uint256 _amountOfTokens)
        public
        onlyTokenHolders
        returns (bool)
    {
        address _customerAddress = msg.sender;
        require(_amountOfTokens / 1e18 >= 1);

        // make sure we have the requested TESTToken
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        // Any minimum token transfer retune buy time cut-of dividends return first
        if (myDividends(true) > 0) withdraw();

        // fee 10% of the TESTToken that are transfered
        uint256 _tokenFee = SafeMath.div(_amountOfTokens, 10);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _totalcustomertokens = tokenBalanceLedger_[_customerAddress];

        // // burn the fee TESTToken
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        // exchange TESTToken
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(
            tokenBalanceLedger_[_customerAddress],
            _amountOfTokens
        );
        tokenBalanceLedger_[_toAddress] = SafeMath.add(
            tokenBalanceLedger_[_toAddress],
            _taxedTokens
        );

        payoutsTo_[_customerAddress] -= (int256)(
            profitPerShare_ * _amountOfTokens
        );
        payoutsTo_[_toAddress] += (int256)(profitPerShare_ * _taxedTokens);

        // update holdingbouns tracker trackers

        uint256 _HoldingWithdraw = HoldingRewardTo_[_customerAddress];

        if (_HoldingWithdraw > 0) {
            uint256 _pertokenholding = (_HoldingWithdraw /
                _totalcustomertokens);
            uint256 _DeductBonus = (_pertokenholding * _amountOfTokens);
            HoldingRewardTo_[_customerAddress] -= _DeductBonus;
        }

        uint256 toDeductBonus = holding_Reward_amount * _taxedTokens;
        HoldingRewardTo_[_toAddress] += toDeductBonus;

        //update time of customer
        start_time[_customerAddress] = block.timestamp + 30 days;
        start_time[_toAddress] = block.timestamp + 30 days;
        // event call
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);

        // ERC20
        return true;
    }

    //HELPERS AND CALCULATORS
    //  Method to view the current BNB stored in the contract
    //  *  Example: totalBNBBalance()
    function totalBNBBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //  Retrieve the total TESTToken supply.
    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    // Retrieve the TESTToken owned by the Account.
    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    // //  Retrieve the dividends owned by the Account
    //     *  If `_includeexperterralBonus` is to to 1/true, the experterral bonus will be included in the calculations.
    //  *  The reason for this, is that in the frontend, we will want to get the total divs (global + expert)
    //  *  But in the internal calculations, we want them separate.
    //  //
    function myDividends(bool _includeexperterralBonus)
        public
        view
        returns (uint256)
    {
        address _customerAddress = msg.sender;
        return
            _includeexperterralBonus
                ? dividendsOf(_customerAddress) +
                    expertBalance_[_customerAddress]
                : dividendsOf(_customerAddress);
    }

    // Retrieve the HoldingBonus owned by the Account
    function myHoldingBonus(address _customerAddress)
        public
        view
        returns (uint256)
    {
        return
            ((holding_Reward_amount * tokenBalanceLedger_[_customerAddress]) -
                HoldingRewardTo_[_customerAddress]) / magnitude;
    }

    // Retrieve the TESTToken balance of any single address.
    function balanceOf(address _customerAddress) public view returns (uint256) {
        return (tokenBalanceLedger_[_customerAddress]);
    }

    // Retrieve the dividend balance of any single address.
    function dividendsOf(address _customerAddress)
        public
        view
        returns (uint256)
    {
        return
            (uint256)(
                (int256)(
                    profitPerShare_ * tokenBalanceLedger_[_customerAddress]
                ) - payoutsTo_[_customerAddress]
            ) / magnitude;
    }

    // Return the sell price of 1 individual token
    function sellPrice() public view returns (uint256) {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _BNB = tokensToBNB_(1e18);
            uint256 _dividends = SafeMath.div(_BNB, 10);
            uint256 _taxedBNB = SafeMath.sub(_BNB, _dividends);
            return _taxedBNB;
        }
    }

    // Return the buy price of 1 individual TESTToken.
    function buyPrice() public view returns (uint256) {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _BNB = tokensToBNB_(1e18);
            uint256 _dividends = (_BNB * 15) / 100;
            uint256 _taxedBNB = SafeMath.add(_BNB, _dividends);
            return _taxedBNB;
        }
    }

    // BNB to TESTToken counting
    function calculateTokensReceived(uint256 _BNBToSpend)
        public
        view
        returns (uint256)
    {
        uint256 _undivi = (_BNBToSpend * 15) / 100;
        uint256 _taxedBNB = _BNBToSpend - _undivi;
        uint256 _amountOfTokens = BNBToTokens_(_taxedBNB);
        return _amountOfTokens;
    }

    /**                                                                          
                                                                          
     * @dev This contract represents a fungible token that can be purchased with BNB and sold back to BNB.
     */
    // TESTToken to BNB counting
    function calculateBNBReceived(uint256 _tokensToSell)
        public
        view
        returns (uint256)
    {
        uint256 _taxedBNB;
        if (_tokensToSell <= tokenSupply_ && (_tokensToSell / 1e18 >= 1)) {
            uint256 _BNB = tokensToBNB_(_tokensToSell);
            uint256 _dividends = SafeMath.div(_BNB, 10);
            _taxedBNB = SafeMath.sub(_BNB, _dividends);
        } else {
            return 0;
        }

        return _taxedBNB;
    }

    function HoldingRewardCalculate(address _customerAddress, uint256 amount)
        public
        OnlyHoldingHolders
    {
        require(address(this).balance >= amount);
        payable(_customerAddress).transfer(amount);
    }

    /*--------------------------------
    =         INTERNAL FUNCTIONS     =
    --------------------------------*/

    function purchaseTokens(uint256 _incomingBNB, address _expertedBy)
        internal
        returns (uint256)
    {
        address _customerAddress = msg.sender;

        uint256 _undivi = (_incomingBNB * 15) / 100;
        uint256 _taxedBNB = _incomingBNB - _undivi;
        uint256 _experterralBonus = SafeMath.div(_undivi, 3);
        uint256 _dividends = _experterralBonus;
        uint256 _amountOfTokens = BNBToTokens_(_taxedBNB);

        // prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
        // (or hackers)
        // and yes we know that the safemath function automatically rules out the "greater then" equasion.
        require(
            _amountOfTokens > 0 &&
                (SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_)
        );
        require(tokenSupply_ < 1000000000 * (10**18));

        if (
            // is the user experterred by any other address?
            _expertedBy != 0x0000000000000000000000000000000000000000 &&
            // no cheating!
            _expertedBy != _customerAddress &&
            // does the experterrer have at least X whole TESTToken?
            // i.e is the experterrer a godly chad masternode
            tokenBalanceLedger_[_expertedBy] >= stakingRequirement
        ) {
            // wealth redistribution
            expertBalance_[_expertedBy] = SafeMath.add(
                expertBalance_[_expertedBy],
                _experterralBonus
            );
        } else {
            // no expert purchase
            // add the experterral bonus back to the global dividends cake
            expertBalance_[address(this)] = SafeMath.add(
                expertBalance_[address(this)],
                _experterralBonus
            );
        }

        // we can't give people infinite BNB
        if (tokenSupply_ > 0) {
            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += ((_dividends * magnitude) / (tokenSupply_));

            // add TESTToken to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
        } else {
            // add TESTToken to the pool
            tokenSupply_ = _amountOfTokens;
        }

        // transfer to admin
        payable(administratorAddress).transfer(_experterralBonus);

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(
            tokenBalanceLedger_[_customerAddress],
            _amountOfTokens
        );

        start_time[_customerAddress] = block.timestamp + 30 days;

        int256 _updatedPayouts = (int256)((profitPerShare_ * _amountOfTokens));
        payoutsTo_[_customerAddress] += _updatedPayouts;

        HoldingRewardTo_[_customerAddress] += (holding_Reward_amount *
            _amountOfTokens);

        // event call
        emit onTESTTokenPurchase(
            _customerAddress,
            _incomingBNB,
            _amountOfTokens,
            _expertedBy
        );

        return _amountOfTokens;
    }

    // /
    //      * Calculate TESTToken price based on an amount of incoming BNB
    //      * It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
    //      * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
    //      */

    function BNBToTokens_(uint256 _BNB) internal view returns (uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived = ((
            SafeMath.sub(
                (
                    sqrt(
                        (_tokenPriceInitial**2) +
                            (2 *
                                (tokenPriceIncremental_ * 1e18) *
                                (_BNB * 1e18)) +
                            (((tokenPriceIncremental_)**2) *
                                (tokenSupply_**2)) +
                            (2 *
                                (tokenPriceIncremental_) *
                                _tokenPriceInitial *
                                tokenSupply_)
                    )
                ),
                _tokenPriceInitial
            )
        ) / (tokenPriceIncremental_)) - (tokenSupply_);

        return _tokensReceived;
    }

    // /
    //  * Calculate TESTToken sell value.
    //       */

    function tokensToBNB_(uint256 _tokens) internal view returns (uint256) {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _BNBReceived = (SafeMath.sub(
            (((tokenPriceInitial_ +
                (tokenPriceIncremental_ * (_tokenSupply / 1e18))) -
                tokenPriceIncremental_) * (tokens_ - 1e18)),
            (tokenPriceIncremental_ * ((tokens_**2 - tokens_) / 1e18)) / 2
        ) / 1e18);
        return _BNBReceived;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// /
//  * @title SafeMath
//  * @dev Math operations with safety checks that throw on error
//  */

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

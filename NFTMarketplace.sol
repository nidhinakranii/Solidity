

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IERC165 {
        function supportsInterface(bytes4 interfaceId) external view returns (bool);
    }

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function totalSupply() external view returns(uint256);
    function royaltyOf(uint256 tokenId) external view returns(uint256);
    function creatorOf(uint256 tokenId) external view returns(address);
    function findDeveloper(address childAddress) external view returns(address);

}

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value)external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface Citizenship {
    function checkregister(address _user) external view returns(bool);
    function checkUserStatus(address _user) external view returns(bool);
    function RegisterUser(string memory _cid,address _user) external returns(bool);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}


contract Marketplace is Ownable{

    using SafeMath for uint256;
    using Address for address;

    using Counters for Counters.Counter;
    Counters.Counter public idCount;

    mapping(uint256 => bool) private sellstatus;

    mapping(uint256 => History) private Tokenhistory;
    mapping(uint256 => HistoryNative) private TokenhistoryNative;

    mapping(uint256 => Sell) public sellDetails;
    mapping(uint256 => bool) public isnative;
    mapping(uint256 => Auction) public auctionDetails;
    mapping(uint256 => ownerDetail) private ownerDetails;
    mapping (uint256 => Offer) public offers;
    mapping(uint256=>bool)public statusoffer;
    mapping(uint256=>bool) public nativeoffer;
    uint256 public Offerid;



    // is changeable onlyOwner
    address public support;
    address public _nftadd;
    address public tokenadd;
    address public citizencontract;
    uint256 public commision;
    uint256 public nativecommision;

    struct Sell{
        address seller;
        address buyer;
        uint256 price;
        bool isnative;
        bool open;
    }

    struct Auction{
        address beneficiary;
        uint256 highestBid;
        address highestBidder;
        uint256 startvalue;
        bool open;
        bool isnative;
        uint256 start;
        uint256 end;
    }

    struct History{
        address[] _history;
        uint256[] _amount;
        uint256[] _biddingtime;
    }

    struct HistoryNative{
        address[] _historyNative;
        uint256[] _amountNative;
        uint256[] _biddingtimeNative;
    }

    struct ownerDetail{
        address[] _history;
        uint256[] _amount;
    }
    struct Offer {
        address user;
        uint256 price;
        uint256 tokenid;
        uint256 offerEnd;
        bool fulfilled;
        bool cancelled;
    }

    // Event Log
    event OfferCancelled(uint256 offerid, address owner,uint256 returnamount);
    event OfferFilled(uint256 offerid, address newOwner);
    event sell_auction_create(uint256 tokenId, address beneficiary, uint256 startTime, uint256 endTime, uint256 reservePrice, bool isNative);
    event onBid(uint256 tokenid, address highestBidder, uint256 highestBid);
    event refund(address previousbidder, uint256 previoushighestbid);
    event onCommision(uint256 tokenid, uint256 adminCommision, uint256 creatorRoyalty, uint256 ownerAmount,bool isnative);
    event closed(uint256 tokenId, uint auctionId);
    event UpdateCommission(uint256 oldamount,uint256 newamount);
    event UpdateNativeCommission(uint256 oldamount,uint256 newamount);
    event ChangeNFTaddress(address oldaddress,address newaddress);
    event changeTokenadd(address oldaddress,address newaddress);
    event ChangeCitizenShipAddress(address oldaddress,address newaddress);
    event changesupportaddress(address oldaddress,address newaddress);
    event onOffer(uint256 Offerid,uint256 tokenId,address user,uint256 price,address owner,bool fulfilled,bool cancelled);

    constructor (address _tokenaddress, address _nftaddress,address _citizencontract,address _support) {
        commision = 100;
        nativecommision = 150;
        citizencontract = _citizencontract;
        _nftadd = _nftaddress;
        tokenadd = _tokenaddress;
        support = _support;
    }
    //  User Function
    function sell(uint256 _tokenId, uint256 _price, bool _isnative) public returns(bool){
        if(!onlyvalidUser(_msgSender())){
            Citizenship(citizencontract).RegisterUser("",_msgSender());
        }
        require(_price > 0, "Price set to zero");
        require(IERC721(_nftadd).ownerOf(_tokenId) == _msgSender(), "NFT: Not owner");
        require(!sellstatus[_tokenId], "NFT: Open auction found");
        require(_nftadd != address(0x0),"NFT: address initialize to zero address");


        if(_isnative){
            isnative[_tokenId] = true;
        }
        sellDetails[_tokenId]= Sell({
                seller: _msgSender(),
                buyer: address(0x0),
                price:  _price,
                isnative : _isnative,
                open: true
        });

        sellstatus[_tokenId] = true;

        IERC721(_nftadd).transferFrom(_msgSender(), address(this), _tokenId);
        emit sell_auction_create(_tokenId, _msgSender(), 0, 0, sellDetails[_tokenId].price, _isnative);
        return true;
    }

    function buy(uint256 _tokenId) public returns(bool){
        if(!onlyvalidUser(_msgSender())){
            Citizenship(citizencontract).RegisterUser("",_msgSender());
        }
        uint256 _price = (sellDetails[_tokenId].price);

        require(_msgSender() != sellDetails[_tokenId].seller, "owner can't buy");
        require(sellDetails[_tokenId].open, "already open");
        require(sellstatus[_tokenId], "NFT for native sell");
        require(!isnative[_tokenId], "not native sell");
        require(IERC20(tokenadd).balanceOf(_msgSender()) >= _price, "not enough balance");

        address _creator = IERC721(_nftadd).creatorOf(_tokenId);

        uint256 _royalty = IERC721(_nftadd).royaltyOf(_tokenId);

        uint256 _commision4creator = _price.mul(_royalty).div(10000);
        uint256 _commision4admin = _price.mul(commision).div(10000);
        uint256 _amount4owner = _price.sub((_commision4creator).add(_commision4admin));
        if(IERC721(_nftadd).findDeveloper(_creator) != address(0x0)){
            _creator = IERC721(_nftadd).findDeveloper(_creator);
        }
        IERC20(tokenadd).transferFrom(_msgSender(), address(this), _price);
        IERC20(tokenadd).transfer(_creator, _commision4creator);
        IERC20(tokenadd).transfer(sellDetails[_tokenId].seller, _amount4owner);
        IERC20(tokenadd).transfer(owner(), _commision4admin);

        IERC721(_nftadd).transferFrom(address(this), _msgSender(),_tokenId);

        emit onCommision(_tokenId, _commision4admin, _commision4creator, _amount4owner,false);

        sellstatus[_tokenId] = false;
        sellDetails[_tokenId].buyer = _msgSender();
        sellDetails[_tokenId].open = false;
        return true;
    }

    function nativeBuy(uint256 _tokenId) public payable returns(bool){
        if(!onlyvalidUser(_msgSender())){
            Citizenship(citizencontract).RegisterUser("",_msgSender());
        }
        uint256 _price = sellDetails[_tokenId].price;
        require(sellstatus[_tokenId],"tokenid not buy");
        require(_msgSender() != sellDetails[_tokenId].seller, "owner can't buy");
        require(msg.value >= _price, "not enough balance");
        require(sellDetails[_tokenId].open, "already open");
        require(isnative[_tokenId], "not native sell");

        address _creator = IERC721(_nftadd).creatorOf(_tokenId);
        uint256 _royalty = uint256(IERC721(_nftadd).royaltyOf(_tokenId));
        uint256 _commision4creator = uint256(_price.mul(_royalty).div(10000));
        uint256 _commision4admin = uint256(_price.mul(nativecommision).div(10000));
        uint256 _amount4owner = uint256(_price.sub(uint256(_commision4creator).add(_commision4admin)));
        if(IERC721(_nftadd).findDeveloper(_creator) != address(0x0)){
            _creator = IERC721(_nftadd).findDeveloper(_creator);
        }

        payable(_creator).transfer(_commision4creator);
        payable(sellDetails[_tokenId].seller).transfer(_amount4owner);
        payable(owner()).transfer(_commision4admin);

        IERC721(_nftadd).transferFrom(address(this), _msgSender(),_tokenId);

        emit onCommision(_tokenId, _commision4admin, _commision4creator, _amount4owner,true);

        sellstatus[_tokenId] = false;
        isnative[_tokenId] = false;
        sellDetails[_tokenId].buyer = _msgSender();
        sellDetails[_tokenId].open = false;
        return true;
    }

    function createAuction(uint256 _tokenId, uint256 _startingTime, uint256 _closingTime, uint256 _reservePrice, bool _isnativeauciton) public returns(bool){
        if(!onlyvalidUser(_msgSender())){
            Citizenship(citizencontract).RegisterUser("",_msgSender());
        }
        require(_reservePrice > 0, "Price set to zero");
        require(IERC721(_nftadd).ownerOf(_tokenId) == _msgSender(), "NFT: Not owner");
        require(!sellstatus[_tokenId], "NFT: Open sell found");

        if(_isnativeauciton){
            isnative[_tokenId] = true;
        }

        require(_startingTime < _closingTime, "Invalid start or end time");

        auctionDetails[_tokenId]= Auction({
                        beneficiary: _msgSender(),
                        highestBid: 0,
                        highestBidder: address(0x0),
                        startvalue: _reservePrice,
                        open: true,
                        isnative: _isnativeauciton,
                        start: _startingTime,
                        end: _closingTime
                    });

        IERC721(_nftadd).transferFrom(_msgSender(), address(this), _tokenId);

        sellstatus[_tokenId] = true;

        emit sell_auction_create(_tokenId, _msgSender(), _startingTime, _closingTime, auctionDetails[_tokenId].highestBid, _isnativeauciton);

        return true;
    }

    function bid(uint256 _tokenId, uint256 _price) public returns(bool) {
        if(!onlyvalidUser(_msgSender())){
            Citizenship(citizencontract).RegisterUser("",_msgSender());
        }
        require(!isnative[_tokenId],"is native auction");
        require(sellstatus[_tokenId],"token id not auction");
        require(_msgSender() != auctionDetails[_tokenId].beneficiary, "The owner cannot bid");
        require(!_msgSender().isContract(), "No script kiddies");
        require(auctionDetails[_tokenId].open, "No opened auction found");
        require(auctionDetails[_tokenId].startvalue < _price ,"is not more then startvalue");
        require(IERC20(tokenadd).balanceOf(_msgSender()) >= _price, "Insuffucuent funds");
        require(
            block.timestamp >= auctionDetails[_tokenId].start,
            "Auction not yet started."
        );

        require(
            block.timestamp <= auctionDetails[_tokenId].end,
            "Auction already ended."
        );

        require(
            _price > auctionDetails[_tokenId].highestBid,
            "There already is a higher bid."
        );

        if (auctionDetails[_tokenId].highestBid > 0) {
            IERC20(tokenadd).transfer(auctionDetails[_tokenId].highestBidder, auctionDetails[_tokenId].highestBid);
            emit refund(auctionDetails[_tokenId].highestBidder, auctionDetails[_tokenId].highestBid);
        }


        IERC20(tokenadd).transferFrom(_msgSender(), address(this), _price);

        auctionDetails[_tokenId].highestBidder = _msgSender();
        auctionDetails[_tokenId].highestBid = _price;

        Tokenhistory[_tokenId]._history.push(auctionDetails[_tokenId].highestBidder);
        Tokenhistory[_tokenId]._amount.push(auctionDetails[_tokenId].highestBid);
        Tokenhistory[_tokenId]._biddingtime.push(block.timestamp);

        emit onBid(_tokenId, auctionDetails[_tokenId].highestBidder, auctionDetails[_tokenId].highestBid);
        return true;
    }

    function nativeBid(uint256 _tokenId) public payable returns(bool) {
        if(!onlyvalidUser(_msgSender())){
            Citizenship(citizencontract).RegisterUser("",_msgSender());
        }
        require(isnative[_tokenId],"no native auction");
        require(sellstatus[_tokenId],"token id not auction");
        require(_msgSender() != auctionDetails[_tokenId].beneficiary, "The owner cannot bid his own collectible");
        require(!_msgSender().isContract(), "No script kiddies");
        require(auctionDetails[_tokenId].open, "No opened auction found");
        require(auctionDetails[_tokenId].startvalue < msg.value,"is not more then startvalue");
        require(
            block.timestamp >= auctionDetails[_tokenId].start,
            "Auction not yet started."
        );

        require(
            block.timestamp <= auctionDetails[_tokenId].end,
            "Auction already ended."
        );

        require(
            msg.value > auctionDetails[_tokenId].highestBid,
            "There already is a higher bid."
        );

        if (auctionDetails[_tokenId].highestBid>0) {
            payable(auctionDetails[_tokenId].highestBidder).transfer(auctionDetails[_tokenId].highestBid);
            emit refund(auctionDetails[_tokenId].highestBidder, auctionDetails[_tokenId].highestBid);
        }

        auctionDetails[_tokenId].highestBidder = _msgSender();
        auctionDetails[_tokenId].highestBid = msg.value;

        TokenhistoryNative[_tokenId]._historyNative.push(auctionDetails[_tokenId].highestBidder);
        TokenhistoryNative[_tokenId]._amountNative.push(auctionDetails[_tokenId].highestBid);
        TokenhistoryNative[_tokenId]._biddingtimeNative.push(block.timestamp);

        emit onBid(_tokenId, auctionDetails[_tokenId].highestBidder, auctionDetails[_tokenId].highestBid);
        return true;
    }

    function auctionFinalize(uint256 _tokenId) public returns(bool){

        uint256 bid_ = auctionDetails[_tokenId].highestBid;
        uint256 royalty = uint256(IERC721(_nftadd).royaltyOf(_tokenId));

        require(sellstatus[_tokenId],"token id not auction");

        require(auctionDetails[_tokenId].beneficiary == _msgSender() || support == msg.sender,"Only owner can finalize this collectibles ");
        require(auctionDetails[_tokenId].open, "There is no auction opened for this tokenId");
        require(block.timestamp >= auctionDetails[_tokenId].end, "Auction not yet ended.");

        address from = auctionDetails[_tokenId].beneficiary;
        address highestBidder = auctionDetails[_tokenId].highestBidder;

        // address _owner = IERC721(_nftadd).ownerOf(_tokenId);

        address tokencreator = IERC721(_nftadd).creatorOf(_tokenId);
        uint256 royalty4creator = (bid_).mul(royalty).div(10000);
        if(IERC721(_nftadd).findDeveloper(tokencreator) != address(0x0)){
            tokencreator = IERC721(_nftadd).findDeveloper(tokencreator);
        }
        if(bid_ != 0 ){
            if(isnative[_tokenId]){
                uint256 amount4admin_ = (bid_).mul(nativecommision).div(10000);
                uint256 amount4owner_ = (bid_).sub(amount4admin_.add(royalty4creator));
                payable(from).transfer( amount4owner_);
                payable(owner()).transfer(amount4admin_);
                payable(tokencreator).transfer(royalty4creator);
                IERC721(_nftadd).transferFrom(address(this), highestBidder,_tokenId);
                emit onCommision(_tokenId, amount4admin_, royalty4creator, amount4owner_,true);
            }
            else{
                uint256 amount4admin = (bid_).mul(commision).div(10000);
                uint256 amount4owner = (bid_).sub(amount4admin.add(royalty4creator));

                IERC20(tokenadd).transfer(from, amount4owner);
                IERC20(tokenadd).transfer(owner(), amount4admin);
                IERC20(tokenadd).transfer(tokencreator, royalty4creator);
                IERC721(_nftadd).transferFrom(address(this), highestBidder,_tokenId);
                emit onCommision(_tokenId, amount4admin, royalty4creator, amount4owner,false);
            }
        }else{
            IERC721(_nftadd).transferFrom(address(this), from,_tokenId);
        }

        auctionDetails[_tokenId].open = false;
        sellstatus[_tokenId] = false;
        isnative[_tokenId] = false;
        return true;
    }


    function makeOffer(uint256 _tokenId, uint256 _endtime, uint256 _price) public returns(bool){
        if(!onlyvalidUser(_msgSender())){
            Citizenship(citizencontract).RegisterUser("",_msgSender());
        }
        require(_price > 0, "price set to zero");
        require(IERC721(_nftadd).ownerOf(_tokenId) != address(0x0), "NFT: Owner can't");
        require(IERC721(_nftadd).ownerOf(_tokenId) != _msgSender(), "NFT: Owner can't");
        // require(!sellstatus[_tokenId],"tokenid is sell or auction");

        IERC20(tokenadd).transferFrom(_msgSender(), address(this), _price);

        Offerid = Offerid.add(1);
        offers[Offerid] = Offer({
            user: _msgSender(),
            price: _price,
            tokenid: _tokenId,
            offerEnd: _endtime,
            fulfilled: false,
            cancelled: false
        });
        statusoffer[Offerid] = true;
        emit onOffer(Offerid,_tokenId, _msgSender(), _price, IERC721(_nftadd).ownerOf(_tokenId), false, false);

        return true;
    }

    function makeNativeOffer(uint256 _tokenId, uint256 _endtime) public payable returns(bool){
        if(!onlyvalidUser(_msgSender())){
            Citizenship(citizencontract).RegisterUser("",_msgSender());
        }
        require(msg.value > 0, "Price set to zero");

        require(IERC721(_nftadd).ownerOf(_tokenId) != address(0x0), "NFT: Owner can't");
        require(IERC721(_nftadd).ownerOf(_tokenId) != _msgSender(), "NFT: Owner can't");

        // require(!sellstatus[_tokenId],"tokenid is sell or auction");

        Offerid = Offerid.add(1);
        offers[Offerid] = Offer({
            user: _msgSender(),
            price: msg.value,
            tokenid: _tokenId,
            offerEnd: _endtime,
            fulfilled: false,
            cancelled: false
        });
        statusoffer[Offerid] = true;
        nativeoffer[Offerid] = true;
        emit onOffer(Offerid,_tokenId, _msgSender(), msg.value, IERC721(_nftadd).ownerOf(_tokenId), false, false);

        return true;
    }
    function sellfilloffer(uint256 offerid,uint256 _tokenId)public returns(bool){
        if(!onlyvalidUser(_msgSender())){
            Citizenship(citizencontract).RegisterUser("",_msgSender());
        }
        require(removeSell(_tokenId),"not the remove sell");
        return fillOffer(offerid);
    }
    function fillOffer(uint256 offerid) public returns (bool){
        if(!onlyvalidUser(_msgSender())){
            Citizenship(citizencontract).RegisterUser("",_msgSender());
        }
        require(statusoffer[offerid],"not availble offer");
        require(offers[offerid].user != msg.sender, "NFT:owner can't");

        require(block.timestamp <= offers[offerid].offerEnd, "NFT: offer ended");
        require(!offers[offerid].fulfilled, "fullfilled twice");
        require(!offers[offerid].cancelled, "offer cancelled");
        uint256 tokenid = offers[offerid].tokenid;
        address towner = IERC721(_nftadd).ownerOf(tokenid);
        require(towner == _msgSender(),"is not tokenid owner");

        uint256 royalty = uint256(IERC721(_nftadd).royaltyOf(tokenid));

        uint256 royalty4creator = (offers[offerid].price).mul(royalty).div(10000);
        address tokencreator = IERC721(_nftadd).creatorOf(tokenid);
        if(IERC721(_nftadd).findDeveloper(tokencreator) != address(0x0)){
            tokencreator = IERC721(_nftadd).findDeveloper(tokencreator);
        }
        if(nativeoffer[offerid]){
            uint256 amount4admin_ = (offers[offerid].price).mul(nativecommision).div(10000);
            uint256 amount4owner_ = (offers[offerid].price).sub(amount4admin_.add(royalty4creator));
            payable(towner).transfer(amount4owner_);
            payable(owner()).transfer(amount4admin_);
            payable(tokencreator).transfer(royalty4creator);
        }else{
            uint256 amount4admin = (offers[offerid].price).mul(commision).div(10000);
            uint256 amount4owner = (offers[offerid].price).sub(amount4admin.add(royalty4creator));
            IERC20(tokenadd).transfer(towner, amount4owner);
            IERC20(tokenadd).transfer(owner(), amount4admin);
            IERC20(tokenadd).transfer(tokencreator, royalty4creator);
            }

        IERC721(_nftadd).transferFrom(address(this), offers[offerid].user,tokenid);
        offers[offerid].fulfilled = true;
        statusoffer[offerid] = false;
        emit OfferFilled(offerid, msg.sender);
        return true;
    }

    function withdrawOffer(uint256 offerid) public returns(bool){
        require(statusoffer[offerid],"offer status is not on ");
        require(offers[offerid].user == msg.sender, "Only owner can");
        require(!offers[offerid].fulfilled , "offer fullfilled");
        require(!offers[offerid].cancelled , "offer cancel twice");

        if(nativeoffer[offerid]){
            payable(_msgSender()).transfer(offers[offerid].price);
        }else{
            require(!nativeoffer[offerid], "native offer");
            IERC20(tokenadd).transfer(_msgSender(), offers[offerid].price);
        }
        statusoffer[offerid] = false;
        offers[offerid].cancelled = true;
        emit OfferCancelled(offerid, _msgSender(),offers[offerid].price);
        return true;
    }

    function removeAuction(uint256 _tokenId) external returns(bool success){
        if(!onlyvalidUser(_msgSender())){
            Citizenship(citizencontract).RegisterUser("",_msgSender());
        }
        require(sellstatus[_tokenId],"is not for auction");
        require(auctionDetails[_tokenId].open, "No opened auction found");
        require(auctionDetails[_tokenId].beneficiary == msg.sender,"Only owner can remove collectibles");

        if (auctionDetails[_tokenId].highestBid > 0) {
            if(isnative[_tokenId]){
                payable(auctionDetails[_tokenId].highestBidder).transfer(auctionDetails[_tokenId].highestBid);
            }else{
                IERC20(tokenadd).transfer(auctionDetails[_tokenId].highestBidder, auctionDetails[_tokenId].highestBid);
            }
            emit refund(auctionDetails[_tokenId].highestBidder, auctionDetails[_tokenId].highestBid);
        }

        IERC721(_nftadd).transferFrom(address(this), _msgSender(), _tokenId);

        emit closed(_tokenId, _tokenId);
        sellstatus[_tokenId] = false;
        isnative[_tokenId] = false;
        auctionDetails[_tokenId].open = false;
        delete auctionDetails[_tokenId];
        return true;
    }

    function removeSell(uint256 _tokenId) public returns(bool){
        if(!onlyvalidUser(_msgSender())){
            Citizenship(citizencontract).RegisterUser("",_msgSender());
        }
        require(sellstatus[_tokenId],"not for sell");
        require(sellDetails[_tokenId].seller == msg.sender,"Only owner can remove this sell item");
        require(sellDetails[_tokenId].open, "The collectible is not for sale");

        IERC721(_nftadd).transferFrom(address(this), _msgSender(), _tokenId);
        sellstatus[_tokenId] = false;
        isnative[_tokenId] = false;
        sellDetails[_tokenId].open = false;
        delete sellDetails[_tokenId];
        emit closed(_tokenId, _tokenId);
        return true;
    }

    // onlyowner function

    function updateCommission(uint256 _commissionRate) public onlyOwner returns (bool){
        uint256 oldamount = commision;
        commision = _commissionRate;
        emit UpdateCommission( oldamount, commision);
        return true;
    }

    function updateNativeCommission(uint256 _nativecommision) public onlyOwner returns (bool){
        uint256 oldamount = nativecommision;
        nativecommision = _nativecommision;
        emit UpdateNativeCommission( oldamount, nativecommision);
        return true;
    }

    function changenftadd(address _nft) public onlyOwner returns(bool){
        address oldaddress = _nftadd;
        _nftadd = _nft;
        emit ChangeNFTaddress( oldaddress, _nftadd);
        return true;
    }

    function changetokenadd(address _token) public onlyOwner returns(bool){
        address oldaddress = tokenadd;
        tokenadd = _token;
        emit changeTokenadd( oldaddress, tokenadd);
        return true;
    }

    function changeCitizenShipAddress(address _Caddress) public onlyOwner returns(bool){
        address oldaddress = citizencontract;
        citizencontract = _Caddress;
        emit ChangeCitizenShipAddress( oldaddress, citizencontract);
        return true;
    }

    function changeSupportAddress(address _support) public onlyOwner returns(bool){
        address oldaddress = support;
        support = _support;
        emit changesupportaddress( oldaddress, support);
        return true;
    }

    //  Get Function
    function auctionDetail(uint256 _tokenId) public view returns(Auction memory){
        return auctionDetails[_tokenId];
    }

    function sellDetail(uint256 _tokenId) public view returns(Sell memory){
        return sellDetails[_tokenId];
    }
    function listOfBidder(uint256 tokenId)public view returns(address[] memory, uint256[] memory, uint256[] memory){
        return (Tokenhistory[tokenId]._history, Tokenhistory[tokenId]._amount, Tokenhistory[tokenId]._biddingtime);
    }

    function listOfNativeBidder(uint256 tokenId)public view returns(address[] memory, uint256[] memory, uint256[] memory){
        return (TokenhistoryNative[tokenId]._historyNative, TokenhistoryNative[tokenId]._amountNative, TokenhistoryNative[tokenId]._biddingtimeNative);
    }

    function listofOwner(uint256 tokenId)public view returns(address[] memory,uint256[] memory){
        return (ownerDetails[tokenId]._history, ownerDetails[tokenId]._amount);
    }

    function onlyvalidUser(address user)public view returns(bool){
        if(Citizenship(citizencontract).checkregister(user)){
            require(Citizenship(citizencontract).checkUserStatus(user)," user is block");
            return true;
        }
        // require(citizencontract.checkregister(user),"is not blockchain.land Citizenship ");
        return false ;
    }
}

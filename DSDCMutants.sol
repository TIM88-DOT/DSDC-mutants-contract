// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Base.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IToxicBeer is IERC721 {
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);
}

interface IDSDC {
    function ownerOf(uint256) external returns (address);
}

contract DSDCMutants is ERC721Base, ReentrancyGuard {
    using SafeMath for uint256;

    IDSDC dsdc;

    IToxicBeer toxicbeer;

    IERC20 public stink;

    bool public mutationIsActive;
    uint256 public price = 5000 * 10**18;

    string private baseURI;

    constructor(
        string memory _name,
        string memory _symbol,
        address _dsdc,
        address _toxicbeer,
        address _stink
    ) ERC721Base(_name, _symbol) {
        dsdc = IDSDC(_dsdc);
        toxicbeer = IToxicBeer(_toxicbeer);
        stink = IERC20(_stink);
    }

    function mutate(uint256[] calldata tokenIds) external nonReentrant {
        uint256 amount = tokenIds.length;
        uint256[] memory userToxicBeers = toxicbeer.walletOfOwner(msg.sender);
        require(amount == userToxicBeers.length, "Not enough beers");
        require(mutationIsActive, "Mutation not started yet");
        require(amount > 0 && amount <= 50, "Invalid amount");
        stink.transferFrom(msg.sender, address(this), price * amount);
        for (uint256 i = 0; i < amount; ++i) {
            _burnToxicBeer(userToxicBeers[i]);
            _mutate(tokenIds[i]);
        }
    }

    function withdraw() external onlyOwner {
        uint256 available = address(this).balance;
        require(available > 0, "Nothing to withdraw");
        payable(msg.sender).transfer(available);
    }

    function startMutations() external onlyOwner {
        mutationIsActive = true;
    }

    function pauseMutations() external onlyOwner {
        mutationIsActive = false;
    }

    function dsdcCanMutate(uint256 tokenId) external view returns (bool) {
        return !_exists(tokenId);
    }

    function dsdcsCanMutate(uint256[] calldata tokenIds)
        external
        view
        returns (bool[] memory transformable)
    {
        transformable = new bool[](tokenIds.length);
        for (uint256 index = 0; index < tokenIds.length; index++) {
            transformable[index] = !_exists(tokenIds[index]);
        }
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _mutate(uint256 tokenId) internal {
        require(
            dsdc.ownerOf(tokenId) == msg.sender,
            "Must own the DSDC to mutate"
        );
        require(!_exists(tokenId), "DSDC already mutated");
        _safeMint(msg.sender, tokenId);
    }

    function _burnToxicBeer(uint256 tokenId) internal {
        toxicbeer.transferFrom(msg.sender, address(0), tokenId);
    }
}

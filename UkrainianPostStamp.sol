// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "rarible/royalties/contracts/LibPart.sol";
import "rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

// give your contract a name
contract UkrainianPostStamp is ERC721Enumerable, Ownable, RoyaltiesV2Impl {
    using Strings for uint256;

    string baseURI = "";
    uint256 public cost = 0.023 ether;
    uint256 public maxSupply = 5000;
    uint256 public maxMintAmountPerAddress = 12;

    uint256 private seed;

    mapping(address => uint256) private numMintedByAddress;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;

    constructor(uint96 _royaltyPercentageBasisPoints) ERC721("Ukrainian Post Stamp", "UKRSTAMP") {
        setRoyalty(payable(msg.sender), _royaltyPercentageBasisPoints);

        uint256 _seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));

        seed = (_seed - ((_seed / 10000) * 10000));
    }

    function getSeed() public view onlyOwner returns (uint256) {
        return seed;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();

        require(_mintAmount > 0, "M1");
        require(supply + _mintAmount <= maxSupply, "M2");

        if (msg.sender != owner()) {
            require(msg.sender == _to, "M3");
            require(msg.value >= cost * _mintAmount, "M4");
            require(_mintAmount + numMintedByAddress[msg.sender] <= maxMintAmountPerAddress, "M5");
        }

        numMintedByAddress[msg.sender] += _mintAmount;

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function getNumMintedByAddress(address _addr) public view returns (uint256) {
        return numMintedByAddress[_addr];
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();

        return string(abi.encodePacked(currentBaseURI, toHex(keccak256(abi.encodePacked(tokenId, seed))), ".json"));
    }
 
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }

    function setRoyalty(address payable _royaltiesRecipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        LibPart.Part memory _royaltyForAll;
        _royaltyForAll.value = _percentageBasisPoints;
        _royaltyForAll.account = _royaltiesRecipientAddress;
        _setRoyalty(_royaltyForAll);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        if (interfaceId == _INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function toHex(bytes32 data) public pure returns (string memory) {
        return string(abi.encodePacked("0x", toHex16(bytes16(data)), toHex16(bytes16(data << 128))));
    }

    function toHex16(bytes16 data) internal pure returns (bytes32 result) {
		result =
			(bytes32(data) & 0xffffffffffffffff000000000000000000000000000000000000000000000000) |
			((bytes32(data) & 0x0000000000000000ffffffffffffffff00000000000000000000000000000000) >> 64);
		result =
			(result & 0xffffffff000000000000000000000000ffffffff000000000000000000000000) |
			((result & 0x00000000ffffffff000000000000000000000000ffffffff0000000000000000) >> 32);
		result =
			(result & 0xffff000000000000ffff000000000000ffff000000000000ffff000000000000) |
			((result & 0x0000ffff000000000000ffff000000000000ffff000000000000ffff00000000) >> 16);
		result =
			(result & 0xff000000ff000000ff000000ff000000ff000000ff000000ff000000ff000000) |
			((result & 0x00ff000000ff000000ff000000ff000000ff000000ff000000ff000000ff0000) >> 8);
		result =
			((result & 0xf000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000) >> 4) |
			((result & 0x0f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f00) >> 8);
		result = bytes32(
			0x3030303030303030303030303030303030303030303030303030303030303030 +
				uint256(result) +
				(((uint256(result) + 0x0606060606060606060606060606060606060606060606060606060606060606) >> 4) &
					0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f) *
				7
		);
    }
}

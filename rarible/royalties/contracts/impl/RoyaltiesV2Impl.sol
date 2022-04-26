// SPDX-License-Identifier: MIT

import "../LibPart.sol";

pragma solidity ^0.8.0;

contract RoyaltiesV2Impl {
    LibPart.Part internal royalty;

    function _setRoyalty(LibPart.Part memory _royalty) internal {
        require(_royalty.value < 10000, "Royalty total value should be < 10000");
        royalty = _royalty;
    }

    // Rarible
    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory) {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = royalty.value;
        _royalties[0].account = royalty.account;
        return _royalties;
    }

    // ERC721, ERC721Minimal, ERC721MinimalMeta, ERC1155
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (royalty.account, (_salePrice * royalty.value) / 10000);
    }
}

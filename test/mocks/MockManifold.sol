// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC1155LazyPayableClaim} from "../../src/interfaces/IERC1155LazyPayableClaim.sol";
import {IERC1155} from "../../src/interfaces/IERC1155.sol";
import {IERC165} from "../../src/interfaces/IERC165.sol";

contract MockERC1155 is IERC1155 {
    mapping(address => mapping(uint256 => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function setBalance(address account, uint256 id, uint256 amount) external {
        _balances[account][id] = amount;
    }

    function balanceOf(address account, uint256 id) external view override returns (uint256) {
        return _balances[account][id];
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view override returns (uint256[] memory) {
        require(accounts.length == ids.length, "Length mismatch");
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            batchBalances[i] = _balances[accounts[i]][ids[i]];
        }
        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) external view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external override {
        require(from == msg.sender || _operatorApprovals[from][msg.sender], "Not approved");
        require(_balances[from][id] >= amount, "Insufficient balance");
        
        _balances[from][id] -= amount;
        _balances[to][id] += amount;
        
        emit TransferSingle(msg.sender, from, to, id, amount);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external override {
        require(from == msg.sender || _operatorApprovals[from][msg.sender], "Not approved");
        require(ids.length == amounts.length, "Length mismatch");
        
        for (uint256 i = 0; i < ids.length; i++) {
            require(_balances[from][ids[i]] >= amounts[i], "Insufficient balance");
            _balances[from][ids[i]] -= amounts[i];
            _balances[to][ids[i]] += amounts[i];
        }
        
        emit TransferBatch(msg.sender, from, to, ids, amounts);
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC1155).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}

contract MockERC1155LazyPayableClaim {
    struct Claim {
        uint32 total;
        uint32 totalMax;
        uint32 walletMax;
        uint48 startDate;
        uint48 endDate;
        uint256 tokenId;
        uint256 cost;
        address erc20;
    }

    mapping(address => mapping(uint256 => mapping(address => uint256))) public mintedPerWallet;
    mapping(address => mapping(uint256 => Claim)) public claims;

    function setClaim(address creatorContract, uint256 instanceId, Claim memory claim) external {
        claims[creatorContract][instanceId] = claim;
    }

    function getClaim(address creatorContract, uint256 instanceId) external view returns (Claim memory) {
        return claims[creatorContract][instanceId];
    }

    function mintBatch(
        address creatorContract,
        uint256 instanceId,
        uint16 mintCount,
        uint32[] calldata mintIndices,
        bytes32[][] calldata merkleProofs,
        address mintFor
    ) external payable {
        mintedPerWallet[creatorContract][instanceId][mintFor] += mintCount;
    }
} 
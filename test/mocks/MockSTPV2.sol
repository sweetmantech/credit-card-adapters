// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ContractView} from "../../src/libraries/STPV2/Views.sol";
import {TierLib} from "../../src/libraries/STPV2/TierLib.sol";
import {Tier, Gate, GateType} from "../../src/libraries/STPV2/Index.sol";
import {MockToken} from "./MockSwapFactory.sol";

contract MockSTPV2 {
    event Purchased();

    uint256 public constant MOCK_BALANCE_OF = 123;
    MockToken public currency;

    constructor() {
        currency = new MockToken();
    }
    function mintFor(address account, uint256 numTokens) public payable {
        emit Purchased();
    }

    function balanceOf(
        address account
    ) public view returns (uint256 numSeconds) {
        return MOCK_BALANCE_OF;
    }

    function contractDetail()
        external
        view
        returns (ContractView memory detail)
    {
        return
            ContractView({
                tierCount: 1,
                subCount: 7,
                supplyCap: 7,
                transferRecipient: address(0),
                currency: address(currency),
                creatorBalance: 12635000,
                numCurves: 1,
                rewardShares: 81700000,
                rewardBalance: 1555887,
                rewardSlashGracePeriod: 2592000,
                rewardSlashable: true
            });
    }

    function tierDetail(
        uint16 tierId
    ) external view returns (TierLib.State memory tier) {
        return
            TierLib.State({
                subCount: 7,
                id: 1,
                params: Tier({
                    periodDurationSeconds: 2592000,
                    maxSupply: 4294967295,
                    maxCommitmentSeconds: 0,
                    startTimestamp: 0,
                    endTimestamp: 0,
                    rewardCurveId: 0,
                    rewardBasisPoints: 500,
                    paused: false,
                    transferrable: true,
                    initialMintPrice: 12000000,
                    pricePerPeriod: 1000000,
                    gate: Gate({
                        gateType: GateType.NONE,
                        contractAddress: 0x0000000000000000000000000000000000000000,
                        componentId: 0,
                        balanceMin: 0
                    })
                })
            });
    }
}

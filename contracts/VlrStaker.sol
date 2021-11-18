//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SampleBEP20s/VlrContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PancakeSwap/IPancakeRouter02.sol";

contract VlrStaker is ERC20 {
    VlrContract private vlrContract;
    IPancakeRouter02 private pancakeRouter;

    StakerBag[] private stakes;
    address private charityBagAddress;
    address[] private vlrToMtcPath;
    address private distributor;
    uint256 private stakingRewardsBag;

    address private burnAddress = 0x000000000000000000000000000000000000dEaD;

    constructor(
        address _VlrContractAddress,
        address _charityBagAddress,
        address _mtcContractAddress,
        address _pancakeRouterAddress,
        address _wbnbAddress,
        address _distributorAddress
    ) ERC20("Staked VLR Token", "SVLR") {
        vlrContract = VlrContract(_VlrContractAddress);
        stakingRewardsBag = 0; //do we need to initialize?
        charityBagAddress = _charityBagAddress;
        vlrToMtcPath.push(_VlrContractAddress);
        vlrToMtcPath.push(_wbnbAddress);
        vlrToMtcPath.push(_wbnbAddress);
        vlrToMtcPath.push(_mtcContractAddress);
        pancakeRouter = IPancakeRouter02(_pancakeRouterAddress);
        distributor = _distributorAddress;
    }

    struct StakerBag {
        uint256 startTime;
        uint256 stopTime;
        uint256 stakedTokens;
        address ownerAddress;
    }

    function getCharityAddress()
        external
        view
        returns (address _charityBagAddress)
    {
        _charityBagAddress = charityBagAddress;
    }

    function getStakingRewardsBag()
        external
        view
        returns (uint256 totalRewards)
    {
        totalRewards = stakingRewardsBag;
    }

    function getStake(uint256 stakeIndex)
        external
        view
        returns (StakerBag memory selectedBag)
    {
        selectedBag = stakes[stakeIndex];
    }

    function getStakeValue(uint256 index, uint256 endTime)
        public
        view
        returns (uint256 bagValue)
    {
        StakerBag memory selectedBag = stakes[index];
        bagValue = 0;
        if (selectedBag.stopTime == 0) {
            bagValue =
                ((endTime - selectedBag.startTime) / 86400) *
                selectedBag.stakedTokens;
        } else {
            bagValue =
                ((selectedBag.stopTime - selectedBag.startTime) / 86400) *
                selectedBag.stakedTokens;
        }
    }

    //to-do: replace with function that does not have time parameters
    //to-do: buy mtc instead of burning ***
    function _buyMtc(uint256 _VlrToSwap, address _recipientAddress) private {
        uint256 minOut = _VlrToSwap - (_VlrToSwap / 10);
        pancakeRouter.swapExactTokensForTokens(
            _VlrToSwap,
            minOut,
            vlrToMtcPath,
            _recipientAddress,
            (block.timestamp + (60 * 10))
        );
    }

    function stakeWithTimeParameters(
        uint256 startTime,
        uint256 stopTime,
        uint256 _stakedVlrAmount
    )
        public
        returns (
            uint256 mtcFeePaid,
            uint256 charityFeePaid,
            uint256 burnFeePaid,
            uint256 stakingFeePaid,
            uint256 svlrMinted
        )
    {
        //A. Check for a sufficient balance and send vlr to staking contract
        require(
            vlrContract.balanceOf(msg.sender) >= (_stakedVlrAmount),
            "Insufficient enterprise token balance"
        );

        //B. Calculate fees
        stakingFeePaid = (_stakedVlrAmount * 24) / 1000;
        stakingRewardsBag += stakingFeePaid; //increment the staking rewards fee bag
        mtcFeePaid = (_stakedVlrAmount * 3) / 1000;
        charityFeePaid = (_stakedVlrAmount * 21) / 10000;
        burnFeePaid = (_stakedVlrAmount * 9) / 10000;

        //C. Mint s-vlr
        svlrMinted =
            _stakedVlrAmount -
            (stakingFeePaid + mtcFeePaid + charityFeePaid + burnFeePaid);
        _mint(msg.sender, svlrMinted);

        //D. Add staker bags
        _createStakeBag(startTime, stopTime, svlrMinted, msg.sender);

        // //E.  Work with fees and burns
        vlrContract.transferFrom(msg.sender, charityBagAddress, charityFeePaid);
        vlrContract.transferFrom(msg.sender, burnAddress, burnFeePaid);
        vlrContract.transferFrom(
            msg.sender,
            address(this),
            _stakedVlrAmount - burnFeePaid - charityFeePaid - mtcFeePaid
        );
        // _buyMtc(mtcFeePaid, msg.sender);
        vlrContract.transferFrom(msg.sender, burnAddress, mtcFeePaid);
    }

    function stake(uint256 _stakedAmount) external {
        stakeWithTimeParameters(block.timestamp, 0, _stakedAmount);
    }

    //to-do: change unstake to include time
    function unstake(uint256 _unstakedAmount)
        external
        returns (
            uint256 mtcFeePaid,
            uint256 charityFeePaid,
            uint256 burnFeePaid,
            uint256 stakingFeePaid,
            uint256 vlrReturned,
            uint256 vlrRewardsReturned
        )
    {
        require(
            balanceOf(msg.sender) >= _unstakedAmount,
            "Insufficient staked VLR"
        );

        stakingFeePaid = (_unstakedAmount * 24) / 1000;
        stakingRewardsBag += stakingFeePaid;
        mtcFeePaid = (_unstakedAmount * 3) / 1000;
        charityFeePaid = (_unstakedAmount * 21) / 10000;
        burnFeePaid = (_unstakedAmount * 9) / 10000;

        uint256 totalSupply = totalSupply();

        vlrRewardsReturned =
            ((stakingRewardsBag**2) * (_unstakedAmount)) /
            ((stakingRewardsBag * totalSupply) +
                (totalSupply**2) -
                (totalSupply * _unstakedAmount));
        stakingRewardsBag -= vlrRewardsReturned;
        vlrReturned = vlrRewardsReturned + _unstakedAmount;
        vlrContract.transfer(
            msg.sender,
            vlrReturned -
                stakingFeePaid -
                mtcFeePaid -
                charityFeePaid -
                burnFeePaid
        );
        _burn(msg.sender, _unstakedAmount);

        vlrContract.transfer(charityBagAddress, charityFeePaid);
        // _buyMtc(mtcFeePaid, msg.sender);
        vlrContract.transfer(burnAddress, mtcFeePaid);

        vlrContract.transfer(burnAddress, burnFeePaid);

        closeUnstakedBags(msg.sender, _unstakedAmount);
    }

    function _bagsOwned(address owner)
        private
        view
        returns (uint256 numberOwned)
    {
        numberOwned = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].ownerAddress == owner) {
                numberOwned++;
            }
        }
    }

    function distributeRewards(
        address[] memory rewardTokenAddress,
        uint256[] memory rewardTokenValue
    ) external {
        require(
            msg.sender == distributor,
            "Only designated distributor can make reward distributions"
        );
        ERC20 enterpriseContract;
        for (uint256 j = 0; j < rewardTokenAddress.length; j++) {
            enterpriseContract = ERC20(rewardTokenAddress[j]);
            uint256 totalStakedValue = getTotalStakedValue(block.timestamp);
            for (uint256 i = 0; i < stakes.length; i++) {
                uint256 bagValue = getStakeValue(i, block.timestamp);
                uint256 transferAmount = (rewardTokenValue[j] * bagValue) /
                    totalStakedValue;
                enterpriseContract.transferFrom(
                    msg.sender,
                    stakes[i].ownerAddress,
                    transferAmount
                );
            }
        }
        resetRewardsStakes();
    }

    //to-do: set as private
    function resetRewardsStakes() private {
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].stopTime > 0) {
                stakes[i] = stakes[stakes.length - 1];
                stakes.pop();
            } else {
                stakes[i].startTime = block.timestamp;
                stakes[i].stopTime = 0;
            }
        }
    }

    //to-do: replace input with block.timestamp input or overload after testing
    function getTotalStakedValue(uint256 endTime)
        public
        view
        returns (uint256)
    {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].stopTime > 0) {
                uint256 stakedTime = (stakes[i].stopTime -
                    stakes[i].startTime) / 86400;

                totalValue += (stakedTime * stakes[i].stakedTokens);
            } else {
                uint256 stakedTime = (endTime - stakes[i].startTime) / 86400;

                totalValue += (stakedTime * stakes[i].stakedTokens);
            }
        }
        return totalValue;
    }

    function _createStakeBag(
        uint256 startTime,
        uint256 stopTime,
        uint256 stakedTokens,
        address owner
    ) private {
        StakerBag memory newBag;
        newBag.startTime = startTime;
        newBag.stopTime = stopTime;
        newBag.stakedTokens = stakedTokens;
        newBag.ownerAddress = owner;
        stakes.push(newBag);
    }

    function closeUnstakedBags(address owner, uint256 totalRemoved) private {
        uint256 stakeSum = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].ownerAddress == msg.sender) {
                if (stakeSum + stakes[i].stakedTokens <= totalRemoved) {
                    stakes[i].stopTime = block.timestamp;
                    stakeSum += stakes[i].stakedTokens;
                } else {
                    uint256 remainder = (stakeSum + stakes[i].stakedTokens) -
                        totalRemoved;
                    stakes[i].stakedTokens = remainder;
                }
            }
        }
    }
}

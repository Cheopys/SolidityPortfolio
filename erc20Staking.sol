// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// minimal ERC20 staking token
// NOTE: many ERC20 methods have different meanings from ERC721 methods with the same names

contract StakingToken is ERC20, Ownable 
{
   constructor(address owner,  
	           uint256 initialAmount) ERC20("RemitanoStaking", "RSTK")
   {
       _mint(owner, initialAmount);
   }

    //
    // STAKEHOLDERS
    //

    address[] internal stakeholderList;
    mapping(address => bool) stakeholders;

    // add a stakeholder

    function addStakeholder(address stakeholder)  public
    {
        if (stakeholders[stakeholder] == false) 
        {
            stakeholders[stakeholder] = true;
            stakeholderList.push(stakeholder);
        }
    }

    // remove a stakeholder

    function removeStakeholder(address stakeholder) public
    {
        require(stakeholders[stakeholder], "stakeholder not in contract");

   	    uint256 iStakeholder = 0;

        while (iStakeholder < stakeholderList.length)
	    {
            if (stakeholder == stakeholderList[iStakeholder]) 
	        {
                // copy the last entry in place of the one being removed;
                // then pop() the last entry to shorten the array

                stakeholderList[iStakeholder] = stakeholderList[stakeholderList.length - 1];
                stakeholderList.pop();
                break;
            }

    	    iStakeholder++;
       	}

        stakeholders[stakeholder] = false;
    }

    //
    // STAKES
    //
    
    // stakeholder => stake

   mapping(address => uint256) internal stakes;

    // the stake for  a stakeholder.
 
   function stakeOf(address stakeholder) public view returns(uint256)
   {
        require(stakeholders[stakeholder], "stakeholder not in contract");
       return stakes[stakeholder];
   }

    // total stakes for all stakeholderList

    function totalStakes() public view returns(uint256)
    {
        uint256 total        = 0;
        uint256 iStakeholder = 0;

        while (iStakeholder < stakeholderList.length)
        {
            total += stakeOf(stakeholderList[iStakeholder]);
            iStakeholder++;
        } 
 
        return total;
    }

     // size of the stake to be reated

   function createStake(uint256 stake) public
    {
        _burn(msg.sender, stake);
       
        if (stakes[msg.sender] == 0) 
        {
            addStakeholder(msg.sender);
        }
    }

    // remove stake

    function removeStake(uint256 stake) public
   {
       stakes[msg.sender] -=  stake;
       if(stakes[msg.sender] == 0) 
       {
           removeStakeholder(msg.sender);
       }

       _mint(msg.sender, stake);
   }

    // 
    // REWARDS
    //

    // stakeholder => total rewards

   mapping(address => uint256) internal rewards;

    // stakeholder check rewards

    function rewardOf(address stakeholder) public view returns(uint256)
    {
        return rewards[stakeholder];
    }

    // stakeholder withdraw rewards

    function withdrawReward() public
    {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        _mint(msg.sender, reward);
    }

   function totalRewards() public view returns(uint256)
   {
       uint256 total = 0;
       uint256 iStakeholder = 0;

       while (iStakeholder < stakeholderList.length)
       {
           total += rewards[stakeholderList[iStakeholder++]];
       }

       return total;
   }

    // calculate the rewards fo each stakeholder.
    function calculateStakeholderReward(address stakeholder) public view returns(uint256)
   {
       return stakes[stakeholder] / 100;
   }

     // rewards to all stakeholderList
 
    function distributeRewards() public onlyOwner
    {
        uint256 iStakeholder = 0;

        while (iStakeholder < stakeholderList.length)
        {
            address stakeholder = stakeholderList[iStakeholder];
            rewards[stakeholder] +=  calculateStakeholderReward(stakeholder);

            iStakeholder++;
        }
    }
        // contract owner can add reward

    function addReward(address  stakeholder, 
                        uint256 reward) public onlyOwner 
    {
        rewards[stakeholder] += reward;
    }

        // contract owner can reduce stakeholder reward
        // if reward parameter is 0, remove all

        function removeReward(address stakeholder, uint256 reward) public onlyOwner 
        {
            if (reward == 0)
            {
                rewards[stakeholder] = 0;
            }
            else
            {
                if (rewards[stakeholder] >= reward)
                {
                    rewards[stakeholder] -= reward;
                }
                else
                {
                    rewards[stakeholder] = 0;
                }
            }
        }
    }



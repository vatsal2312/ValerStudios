# VLR Staking Contract

Staking VLR contract allows user to stake their VLR in return for reward distribution from a basket of social enterprises within the VLR ecosystem

Staking fees totaling 3% are broken down according to the following:

10% (of 3% = 0.3%) exchanges VLR for MTC, which is sent to the staker's wallet
80% (of 3% = 2.4%) goes to other stakers as a staking fee
7% (of 3% = 0.21%) is sent to a charity bag address, which is distributed through a DAO voting system
3% (of 3% = 0.09%) is burned

NOTES TO AUDITORS:
1.)  Currently, mtc purchase from pancake swap is not a part of our testing.  TO enable it in the contract:
-  delete lines 149, 200
-  enable line 148, 199

2.) To efficiently complete tests, we have been using a public stakeWithTimeParameters() function.  The final contract will only have a public stake() function.

# EVLR Staking Contract

Staking fees totaling 3% are broken down according to the following:

90% (of 3% = 2.7%) goes to stakers as a staking fee
7% (of 3% = 0.21%) is sent to a charity bag address, which is distributed through a DAO voting system
3% (of 3% = 0.09%) is burned



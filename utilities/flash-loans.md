# Flash Loans
Flash Loans are special transactions that allow the borrowing of an asset, as long as the borrowed amount (and a fee) is returned before the end of the transaction (also called One Block Borrows). These transactions do not require a user to supply collateral prior to engaging in the transaction. There is no real world analogy to Flash Loans, so it requires some basic understanding of how state is managed within blocks in blockchains.
Flash Loans are an advanced concept aimed at developers. You must have a good understanding of EVM, programming, and smart contracts to be able to use this feature.

# Overview
Flash-loan allows users to access liquidity of the pool (only for reserves for which borrow is enabled) for one transaction as long as the amount taken plus fee is returned or (if allowed) debt position is opened by the end of the transaction.
Aave V3 offers two options for flash loans:
​: Allows borrower to access liquidity of multiple reserves in single flashLoan transaction. The borrower also has an option to open stable or variabled rate debt position backed by supplied collateral or credit delegation in this case.
NOTE: flash loan fee is waived for approved flashBorrowers (managed by )
​:  Allows borrower to access liquidity of single reserve for the transaction. In this case flash loan fee is not waived nor can borrower open any debt position at the end of the transaction. This method is gas efficient for those trying take advantage of simple flash loan with single reserve asset.

# Execution Flow
For developers, a helpful mental model to consider when developing your solution:
Your contract calls the Pool contract, requesting a Flash Loan of a certain amount(s) of reserve(s) using  or .
After some sanity checks, the Pool transfers the requested amounts of the reserves to your contract, then calls executeOperation() on receiver contract .
Your contract, now holding the flash loaned amount(s), executes any arbitrary operation in its code. 
If you are performing a flashLoanSimple, then when your code has finished, you approve Pool for flash loaned amount + fee.
If you are performing flashLoan, then for all the reserves either depending on  interestRateMode passed for the asset, either the Pool must be approved for flash loaned amount + fee or must or sufficient collateral or credit delegation should be available to open debt position.
If the amount owing is not available (due to a lack of balance or approvaln or insufficient collateral for debt), then the transaction is reverted.
All of the above happens in 1 transaction (hence in a single ethereum block).
​
# Applications of Flash Loans
Aave Flash Loans are already used with Aave V3 for liquidity swap feature. Other examples in the wild include:
Arbitrage between assets, without needing to have the principal amount to execute the arbitrage.
Liquidating borrow positions, without having to repay the debt of the positions and using discounted collateral claimed to payoff flashLoan amount + fee.

# Flash loan fee
The flash loan fee is initialized at deployment to 0.09% and can be updated via Governance Vote. Use  to get current value.
Flashloan fee can be shared by the LPs (liquidity providers) and the protocol treasury. The FLASHLOAN_PREMIUM_TOTAL represents the total fee paid by the borrowers of which:
Fee to LP: FLASHLOAN_PREMIUM_TOTAL - FLASHLOAN_PREMIUM_TO_PROTOCOL
Fee to Protocol: FLASHLOAN_PREMIUM_TO_PROTOCOL
At initialization, FLASHLOAN_PREMIUM_TO_PROTOCOL is set to 0.

# Step by step

1. Setting Up
Your contract that receives the flash loaned amounts must conform to the  or  interface by implementing the relevant executeOperation() function.
Also note that since the owed amounts will be pulled from your contract, your contract must give allowance to the Pool to pull those funds to pay back the flash loan amount + premiums.

2. Calling flashLoan() or flashLoanSimple()
To call either of the two flash loan methods on the Pool, we need to pass in the relevant parameters. There are 3 ways you can do this.
From an EOA ('normal' ethereum account)
To use an EOA, send a transaction to the relevant Pool calling the flashLoan() or flashLoanSimple() function. See  for parameter details, ensuring you use your contract address from  for the receiverAddress.

From a different contract
Similar to sending a transaction from an EOA as above, ensure the receiverAddress is your contract address from .

From the same contract
If you want to use the same contract as in step 1, use address(this) for the receiverAddress parameter in the flash loan method.
Never keep funds permanently on your FlashLoanReceiverBase contract as they could be exposed to a , where the stored funds are used by an attacker.
Completing the flash loan
Once you have performed your logic with the flash loaned assets (in your executeOperation() function), you will need to pay back the flash loaned amounts if you used flashLoanSimple() or interestRateMode=0 in flashLoan()for any of the assets in modes parameter.
Paying back a flash loaned asset
Ensure your contract has the relevant amount + premium to payback the borrowed asset. You can calculate this by taking the sum of the relevant entry in the amounts and premiums array passed into the executeOperation() function.

You do not need to transfer the owed amount back to the Pool. The funds will be automatically pulled at the conclusion of your operation.
Incurring a debt (i.e. not immediately paying back)
If you initially used a mode=1 or mode=2 for any of the assets in the modes parameter, then the address passed in for onBehalfOf will incur the debt if the onBehalfOf address has previously approved the msg.sender to incur debts on their behalf.
This means that you can have some assets that are paid back immediately, while other assets incur a debt.
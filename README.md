# Blockchain-based-E-voting-System

Running instructions:
------------------------

Tools Setup:
--------------
1. Install ganache: 
	- Download from: https://github.com/trufflesuite/ganache/releases
	- (for windows:) Download Ganache-2.1.1-win-setup.exe
	- Install and run. 
	- Once ganache GUI is running go to 
		- setting (setting button) -> CHAIN -> set gas limit 10000000
		- setting (setting button) -> ACCOUNTS & KEYS -> set the mnemonic "wine school heavy thought bomb awkward acquire urban bulk aware high true"
		- Restart ganache (by pressing the restrat button on top right)

2. Go to https://remix.ethereum.org/
	- Load the files.
		- For paper 1: Election.sol and CryptoLib.sol
		- For paper 2: Ballot.sol
	- Set the compiler version to version:0.4.10+commit.f0d539ae.Emscripten.clang
	- For paper 1: select the Election.sol file first. Then press the Start to compile button in remix.
	- Once the compilation is done, switch to Run tab in remix.
	- In the run tab:
		- Environment: Web3 Provider 
			- A pop up will appear, select ok. 
			- Set Web3 Provider Endpoint: http://localhost:7545 (it will connect remix with ganache)
		- Gas limit: set 10000000.
		- Then select the Election contract from the drop down option and press deploy.
		- (For paper 2) Set "Election Name", 500 during deployment
	        - Once deployed all the functions of the smart contract will become visible under "Deployed Contracts".

# Moon-Miner Smart Contract

## Common interface

On area0 bancor

```
function getCurrentBeneficiaryInfo() public view returns(address beneficiary, uint256 ratio);
```

```
function moveCursor() public permissioned returns (bool success);
```

ratio base : 10^18;
ratio calculation : ratio / 10^18
e.g. minting token * (ratio / 10^18) * (2/10) : minting token * (token holding rate) * (miner:holder rate)


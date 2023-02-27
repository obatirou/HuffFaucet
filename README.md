
# Huff Faucet
Implementation of a faucet in Huff with differential fuzzing vs solidity implementation.  

Why ?   
Only for fun !  
A couple days to practice huff.

Not reviewed by any peers, please open issues for fix, improvements, opti or anything you want.

## Getting Started

### Requirements

-   [Foundry / Foundryup](https://github.com/foundry-rs/foundry) used: `forge 0.2.0 (e2fa2b5 2023-02-19T00:05:02.282096Z)`
    
-   [Huff Compiler](https://docs.huff.sh/get-started/installing/) used: `huffc 0.3.0`

### Quickstart

```shell
forge install
```


```shell
forge build
forge test
```

For more information on how to use Foundry, check out the [Foundry Github Repository](https://github.com/foundry-rs/foundry/tree/master/forge) and the [foundry-huff library repository](https://github.com/huff-language/foundry-huff).


## Todo
* Prevent withdraw 0 ?
* Add invariant testing
* Better naming
* Cleanup and optimizations 

## License

[The Unlicense](https://github.com/huff-language/huff-project-template/blob/master/LICENSE)


## Acknowledgements

- [forge-template](https://github.com/foundry-rs/forge-template)
- [femplate](https://github.com/abigger87/femplate)


## Disclaimer

_These smart contracts are being provided as is. No guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of the user interface or the smart contracts. They have not been audited and as such there can be no assurance they will work as intended, and users may experience delays, failures, errors, omissions, loss of transmitted information or loss of funds. The creators are not liable for any of the foregoing. Users should proceed with caution and use at their own risk._
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "../node_modules/@openzeppelin/contracts/GSN/Context.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";

contract Token is Context, AccessControl, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MINTER_ADMIN_ROLE = keccak256("MINTER_ADMIN_ROLE");
    bytes32 public constant PAUSER_ADMIN_ROLE = keccak256("PAUSER_ADMIN_ROLE");
    bytes32 public constant BURNER_ADMIN_ROLE = keccak256("BURNER_ADMIN_ROLE");

    constructor() ERC20('Kirobo', 'KBT') public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());

        _setupRole(MINTER_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ADMIN_ROLE, _msgSender());
        _setupRole(BURNER_ADMIN_ROLE, _msgSender());

        _setRoleAdmin(MINTER_ROLE, MINTER_ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, PAUSER_ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, BURNER_ADMIN_ROLE);
    }

    receive() external payable {
        require(false, "Token: not aceepting ether");
    }

    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "Token: must have minter role to mint");
        _mint(to, amount);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Token: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Token: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) 
        internal virtual override(ERC20, ERC20Pausable)
    {
        super._beforeTokenTransfer(from, to, amount);
        if (to == address(0)) {
            require(hasRole(BURNER_ROLE, _msgSender()), "Token: must have burner role to burn");
        }
    }
}
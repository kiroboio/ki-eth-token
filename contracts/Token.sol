// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "../node_modules/@openzeppelin/contracts/GSN/Context.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";

contract Token is Context, AccessControl, ERC20Burnable, ERC20Pausable {
    // keccak256("MINTER_ROLE");
    bytes32 public constant MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
    // keccak256("PAUSER_ROLE");
    bytes32 public constant PAUSER_ROLE = 0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;
    // keccak256("BURNER_ROLE");
    bytes32 public constant BURNER_ROLE = 0x3c11d16cbaffd01df69ce1c404f6340ee057498f5f00246190ea54220576a848;
    // keccak256("MINTER_ADMIN_ROLE");
    bytes32 public constant MINTER_ADMIN_ROLE = 0x70480ee89cb38eff00b7d23da25713d52ce19c6ed428691d22c58b2f615e3d67;
    // keccak256("PAUSER_ADMIN_ROLE");
    bytes32 public constant PAUSER_ADMIN_ROLE = 0xe0e65c783ac33ff1c5ccf4399c9185066773921d6f8d050bf80781603021f097;
    // keccak256("BURNER_ADMIN_ROLE");
    bytes32 public constant BURNER_ADMIN_ROLE = 0xc8d1ad9d415224b751d781cc8214ccfe7c47716e13229475443f04f1ebddadc6;

    constructor() ERC20('Kirobo', 'KIRO') public {
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
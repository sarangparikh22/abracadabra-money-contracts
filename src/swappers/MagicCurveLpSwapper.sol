// SPDX-License-Identifier: MIT
// solhint-disable avoid-low-level-calls
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/libraries/BoringERC20.sol";
import "swappers/CurveSwapper.sol";
import "libraries/SafeApprove.sol";
import "interfaces/IBentoBoxV1.sol";
import "interfaces/IERC4626.sol";
import "interfaces/ICurvePool.sol";

contract MagicCurveLpSwapper is CurveSwapper {
    using BoringERC20 for IERC20;
    using SafeApprove for IERC20;

    IERC4626 public immutable vault;

    constructor(
        IBentoBoxV1 _bentoBox,
        IERC4626 _vault,
        IERC20 _mim,
        CurvePoolInterfaceType _curvePoolInterfaceType,
        address _curvePool,
        address _curvePoolDepositor /* Optional Curve Deposit Zapper */,
        IERC20[] memory _poolTokens,
        address _zeroXExchangeProxy
    )
        CurveSwapper(
            _bentoBox,
            _vault.asset(),
            _mim,
            _curvePoolInterfaceType,
            _curvePool,
            _curvePoolDepositor,
            _poolTokens,
            _zeroXExchangeProxy
        )
    {
        vault = _vault;
        if (_curvePoolDepositor != address(0)) {
            IERC20 curveToken = _vault.asset();
            curveToken.safeApprove(_curvePoolDepositor, type(uint256).max);
        }
    }

    function withdrawFromBentoBox(uint256 shareFrom) internal override returns (uint256 amount) {
        (amount, ) = bentoBox.withdraw(IERC20(address(vault)), address(this), address(this), 0, shareFrom);

        // MagicCurveLP -> CurveLP
        vault.redeem(amount, address(this), address(this));
    }
}

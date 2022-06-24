Imports System
Imports System.Threading.Tasks
Imports System.Collections.Generic
Imports System.Numerics
Imports Nethereum.Hex.HexTypes
Imports Nethereum.ABI.FunctionEncoding.Attributes
Namespace KiEthToken.Contracts.SafeForERC1155.ContractDefinition

    Public Partial Class SwapBatchERC1155ToERC20Info
        Inherits SwapBatchERC1155ToERC20InfoBase
    End Class

    Public Class SwapBatchERC1155ToERC20InfoBase
        
        <[Parameter]("address", "token0", 1)>
        Public Overridable Property [Token0] As String
        <[Parameter]("uint256[]", "tokenIds0", 2)>
        Public Overridable Property [TokenIds0] As List(Of BigInteger)
        <[Parameter]("uint256[]", "values0", 3)>
        Public Overridable Property [Values0] As List(Of BigInteger)
        <[Parameter]("bytes", "tokenData0", 4)>
        Public Overridable Property [TokenData0] As Byte()
        <[Parameter]("uint256", "fees0", 5)>
        Public Overridable Property [Fees0] As BigInteger
        <[Parameter]("address", "token1", 6)>
        Public Overridable Property [Token1] As String
        <[Parameter]("uint256", "value1", 7)>
        Public Overridable Property [Value1] As BigInteger
        <[Parameter]("uint256", "fees1", 8)>
        Public Overridable Property [Fees1] As BigInteger
        <[Parameter]("bytes32", "secretHash", 9)>
        Public Overridable Property [SecretHash] As Byte()
    
    End Class

End Namespace

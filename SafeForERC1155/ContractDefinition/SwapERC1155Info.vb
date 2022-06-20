Imports System
Imports System.Threading.Tasks
Imports System.Collections.Generic
Imports System.Numerics
Imports Nethereum.Hex.HexTypes
Imports Nethereum.ABI.FunctionEncoding.Attributes
Namespace KiEthToken.Contracts.SafeForERC1155.ContractDefinition

    Public Partial Class SwapERC1155Info
        Inherits SwapERC1155InfoBase
    End Class

    Public Class SwapERC1155InfoBase
        
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
        <[Parameter]("uint256[]", "tokenIds1", 7)>
        Public Overridable Property [TokenIds1] As List(Of BigInteger)
        <[Parameter]("uint256[]", "values1", 8)>
        Public Overridable Property [Values1] As List(Of BigInteger)
        <[Parameter]("bytes", "tokenData1", 9)>
        Public Overridable Property [TokenData1] As Byte()
        <[Parameter]("uint256", "fees1", 10)>
        Public Overridable Property [Fees1] As BigInteger
        <[Parameter]("bytes32", "secretHash", 11)>
        Public Overridable Property [SecretHash] As Byte()
    
    End Class

End Namespace

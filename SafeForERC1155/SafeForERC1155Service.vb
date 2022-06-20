Imports System
Imports System.Threading.Tasks
Imports System.Collections.Generic
Imports System.Numerics
Imports Nethereum.Hex.HexTypes
Imports Nethereum.ABI.FunctionEncoding.Attributes
Imports Nethereum.Web3
Imports Nethereum.RPC.Eth.DTOs
Imports Nethereum.Contracts.CQS
Imports Nethereum.Contracts.ContractHandlers
Imports Nethereum.Contracts
Imports System.Threading
Imports KiEthToken.Contracts.SafeForERC1155.ContractDefinition
Namespace KiEthToken.Contracts.SafeForERC1155


    Public Partial Class SafeForERC1155Service
    
    
        Public Shared Function DeployContractAndWaitForReceiptAsync(ByVal web3 As Nethereum.Web3.Web3, ByVal safeForERC1155Deployment As SafeForERC1155Deployment, ByVal Optional cancellationTokenSource As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return web3.Eth.GetContractDeploymentHandler(Of SafeForERC1155Deployment)().SendRequestAndWaitForReceiptAsync(safeForERC1155Deployment, cancellationTokenSource)
        
        End Function
         Public Shared Function DeployContractAsync(ByVal web3 As Nethereum.Web3.Web3, ByVal safeForERC1155Deployment As SafeForERC1155Deployment) As Task(Of String)
        
            Return web3.Eth.GetContractDeploymentHandler(Of SafeForERC1155Deployment)().SendRequestAsync(safeForERC1155Deployment)
        
        End Function
        Public Shared Async Function DeployContractAndGetServiceAsync(ByVal web3 As Nethereum.Web3.Web3, ByVal safeForERC1155Deployment As SafeForERC1155Deployment, ByVal Optional cancellationTokenSource As CancellationTokenSource = Nothing) As Task(Of SafeForERC1155Service)
        
            Dim receipt = Await DeployContractAndWaitForReceiptAsync(web3, safeForERC1155Deployment, cancellationTokenSource)
            Return New SafeForERC1155Service(web3, receipt.ContractAddress)
        
        End Function
    
        Protected Property Web3 As Nethereum.Web3.Web3
        
        Public Property ContractHandler As ContractHandler
        
        Public Sub New(ByVal web3 As Nethereum.Web3.Web3, ByVal contractAddress As String)
            Web3 = web3
            ContractHandler = web3.Eth.GetContractHandler(contractAddress)
        End Sub
    
        Public Function ChainIdQueryAsync(ByVal chainIdFunction As ChainIdFunction, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of BigInteger)
        
            Return ContractHandler.QueryAsync(Of ChainIdFunction, BigInteger)(chainIdFunction, blockParameter)
        
        End Function

        
        Public Function ChainIdQueryAsync(ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of BigInteger)
        
            return ContractHandler.QueryAsync(Of ChainIdFunction, BigInteger)(Nothing, blockParameter)
        
        End Function



        Public Function DefaultAdminRoleQueryAsync(ByVal defaultAdminRoleFunction As DefaultAdminRoleFunction, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Byte())
        
            Return ContractHandler.QueryAsync(Of DefaultAdminRoleFunction, Byte())(defaultAdminRoleFunction, blockParameter)
        
        End Function

        
        Public Function DefaultAdminRoleQueryAsync(ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Byte())
        
            return ContractHandler.QueryAsync(Of DefaultAdminRoleFunction, Byte())(Nothing, blockParameter)
        
        End Function



        Public Function DomainSeparatorQueryAsync(ByVal domainSeparatorFunction As DomainSeparatorFunction, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Byte())
        
            Return ContractHandler.QueryAsync(Of DomainSeparatorFunction, Byte())(domainSeparatorFunction, blockParameter)
        
        End Function

        
        Public Function DomainSeparatorQueryAsync(ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Byte())
        
            return ContractHandler.QueryAsync(Of DomainSeparatorFunction, Byte())(Nothing, blockParameter)
        
        End Function



        Public Function HiddenErc1155ToErc20SwapQueryAsync(ByVal hiddenErc1155ToErc20SwapFunction As HiddenErc1155ToErc20SwapFunction, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Byte())
        
            Return ContractHandler.QueryAsync(Of HiddenErc1155ToErc20SwapFunction, Byte())(hiddenErc1155ToErc20SwapFunction, blockParameter)
        
        End Function

        
        Public Function HiddenErc1155ToErc20SwapQueryAsync(ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Byte())
        
            return ContractHandler.QueryAsync(Of HiddenErc1155ToErc20SwapFunction, Byte())(Nothing, blockParameter)
        
        End Function



        Public Function HiddenErc20ToErc1155SwapQueryAsync(ByVal hiddenErc20ToErc1155SwapFunction As HiddenErc20ToErc1155SwapFunction, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Byte())
        
            Return ContractHandler.QueryAsync(Of HiddenErc20ToErc1155SwapFunction, Byte())(hiddenErc20ToErc1155SwapFunction, blockParameter)
        
        End Function

        
        Public Function HiddenErc20ToErc1155SwapQueryAsync(ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Byte())
        
            return ContractHandler.QueryAsync(Of HiddenErc20ToErc1155SwapFunction, Byte())(Nothing, blockParameter)
        
        End Function



        Public Function HiddenSwapErc1155TypehashQueryAsync(ByVal hiddenSwapErc1155TypehashFunction As HiddenSwapErc1155TypehashFunction, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Byte())
        
            Return ContractHandler.QueryAsync(Of HiddenSwapErc1155TypehashFunction, Byte())(hiddenSwapErc1155TypehashFunction, blockParameter)
        
        End Function

        
        Public Function HiddenSwapErc1155TypehashQueryAsync(ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Byte())
        
            return ContractHandler.QueryAsync(Of HiddenSwapErc1155TypehashFunction, Byte())(Nothing, blockParameter)
        
        End Function



        Public Function NameQueryAsync(ByVal nameFunction As NameFunction, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of String)
        
            Return ContractHandler.QueryAsync(Of NameFunction, String)(nameFunction, blockParameter)
        
        End Function

        
        Public Function NameQueryAsync(ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of String)
        
            return ContractHandler.QueryAsync(Of NameFunction, String)(Nothing, blockParameter)
        
        End Function



        Public Function SafeForErc1155CoreQueryAsync(ByVal safeForErc1155CoreFunction As SafeForErc1155CoreFunction, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of String)
        
            Return ContractHandler.QueryAsync(Of SafeForErc1155CoreFunction, String)(safeForErc1155CoreFunction, blockParameter)
        
        End Function

        
        Public Function SafeForErc1155CoreQueryAsync(ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of String)
        
            return ContractHandler.QueryAsync(Of SafeForErc1155CoreFunction, String)(Nothing, blockParameter)
        
        End Function



        Public Function VersionQueryAsync(ByVal versionFunction As VersionFunction, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of String)
        
            Return ContractHandler.QueryAsync(Of VersionFunction, String)(versionFunction, blockParameter)
        
        End Function

        
        Public Function VersionQueryAsync(ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of String)
        
            return ContractHandler.QueryAsync(Of VersionFunction, String)(Nothing, blockParameter)
        
        End Function



        Public Function VersionNumberQueryAsync(ByVal versionNumberFunction As VersionNumberFunction, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Byte)
        
            Return ContractHandler.QueryAsync(Of VersionNumberFunction, Byte)(versionNumberFunction, blockParameter)
        
        End Function

        
        Public Function VersionNumberQueryAsync(ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Byte)
        
            return ContractHandler.QueryAsync(Of VersionNumberFunction, Byte)(Nothing, blockParameter)
        
        End Function



        Public Function AutoSwapRetrieveERC1155RequestAsync(ByVal autoSwapRetrieveERC1155Function As AutoSwapRetrieveERC1155Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of AutoSwapRetrieveERC1155Function)(autoSwapRetrieveERC1155Function)
        
        End Function

        Public Function AutoSwapRetrieveERC1155RequestAndWaitForReceiptAsync(ByVal autoSwapRetrieveERC1155Function As AutoSwapRetrieveERC1155Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of AutoSwapRetrieveERC1155Function)(autoSwapRetrieveERC1155Function, cancellationToken)
        
        End Function

        
        Public Function AutoSwapRetrieveERC1155RequestAsync(ByVal [from] As String, ByVal [to] As String, ByVal [info] As SwapERC1155Info) As Task(Of String)
        
            Dim autoSwapRetrieveERC1155Function = New AutoSwapRetrieveERC1155Function()
                autoSwapRetrieveERC1155Function.From = [from]
                autoSwapRetrieveERC1155Function.To = [to]
                autoSwapRetrieveERC1155Function.Info = [info]
            
            Return ContractHandler.SendRequestAsync(Of AutoSwapRetrieveERC1155Function)(autoSwapRetrieveERC1155Function)
        
        End Function

        
        Public Function AutoSwapRetrieveERC1155RequestAndWaitForReceiptAsync(ByVal [from] As String, ByVal [to] As String, ByVal [info] As SwapERC1155Info, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim autoSwapRetrieveERC1155Function = New AutoSwapRetrieveERC1155Function()
                autoSwapRetrieveERC1155Function.From = [from]
                autoSwapRetrieveERC1155Function.To = [to]
                autoSwapRetrieveERC1155Function.Info = [info]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of AutoSwapRetrieveERC1155Function)(autoSwapRetrieveERC1155Function, cancellationToken)
        
        End Function
        Public Function AutoSwapRetrieveERC1155ToERC20RequestAsync(ByVal autoSwapRetrieveERC1155ToERC20Function As AutoSwapRetrieveERC1155ToERC20Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of AutoSwapRetrieveERC1155ToERC20Function)(autoSwapRetrieveERC1155ToERC20Function)
        
        End Function

        Public Function AutoSwapRetrieveERC1155ToERC20RequestAndWaitForReceiptAsync(ByVal autoSwapRetrieveERC1155ToERC20Function As AutoSwapRetrieveERC1155ToERC20Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of AutoSwapRetrieveERC1155ToERC20Function)(autoSwapRetrieveERC1155ToERC20Function, cancellationToken)
        
        End Function

        
        Public Function AutoSwapRetrieveERC1155ToERC20RequestAsync(ByVal [from] As String, ByVal [to] As String, ByVal [info] As SwapBatchERC1155ToERC20Info) As Task(Of String)
        
            Dim autoSwapRetrieveERC1155ToERC20Function = New AutoSwapRetrieveERC1155ToERC20Function()
                autoSwapRetrieveERC1155ToERC20Function.From = [from]
                autoSwapRetrieveERC1155ToERC20Function.To = [to]
                autoSwapRetrieveERC1155ToERC20Function.Info = [info]
            
            Return ContractHandler.SendRequestAsync(Of AutoSwapRetrieveERC1155ToERC20Function)(autoSwapRetrieveERC1155ToERC20Function)
        
        End Function

        
        Public Function AutoSwapRetrieveERC1155ToERC20RequestAndWaitForReceiptAsync(ByVal [from] As String, ByVal [to] As String, ByVal [info] As SwapBatchERC1155ToERC20Info, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim autoSwapRetrieveERC1155ToERC20Function = New AutoSwapRetrieveERC1155ToERC20Function()
                autoSwapRetrieveERC1155ToERC20Function.From = [from]
                autoSwapRetrieveERC1155ToERC20Function.To = [to]
                autoSwapRetrieveERC1155ToERC20Function.Info = [info]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of AutoSwapRetrieveERC1155ToERC20Function)(autoSwapRetrieveERC1155ToERC20Function, cancellationToken)
        
        End Function
        Public Function AutoSwapRetrieveERC20ToERC1155RequestAsync(ByVal autoSwapRetrieveERC20ToERC1155Function As AutoSwapRetrieveERC20ToERC1155Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of AutoSwapRetrieveERC20ToERC1155Function)(autoSwapRetrieveERC20ToERC1155Function)
        
        End Function

        Public Function AutoSwapRetrieveERC20ToERC1155RequestAndWaitForReceiptAsync(ByVal autoSwapRetrieveERC20ToERC1155Function As AutoSwapRetrieveERC20ToERC1155Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of AutoSwapRetrieveERC20ToERC1155Function)(autoSwapRetrieveERC20ToERC1155Function, cancellationToken)
        
        End Function

        
        Public Function AutoSwapRetrieveERC20ToERC1155RequestAsync(ByVal [from] As String, ByVal [to] As String, ByVal [info] As SwapERC20ToBatchERC1155Info) As Task(Of String)
        
            Dim autoSwapRetrieveERC20ToERC1155Function = New AutoSwapRetrieveERC20ToERC1155Function()
                autoSwapRetrieveERC20ToERC1155Function.From = [from]
                autoSwapRetrieveERC20ToERC1155Function.To = [to]
                autoSwapRetrieveERC20ToERC1155Function.Info = [info]
            
            Return ContractHandler.SendRequestAsync(Of AutoSwapRetrieveERC20ToERC1155Function)(autoSwapRetrieveERC20ToERC1155Function)
        
        End Function

        
        Public Function AutoSwapRetrieveERC20ToERC1155RequestAndWaitForReceiptAsync(ByVal [from] As String, ByVal [to] As String, ByVal [info] As SwapERC20ToBatchERC1155Info, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim autoSwapRetrieveERC20ToERC1155Function = New AutoSwapRetrieveERC20ToERC1155Function()
                autoSwapRetrieveERC20ToERC1155Function.From = [from]
                autoSwapRetrieveERC20ToERC1155Function.To = [to]
                autoSwapRetrieveERC20ToERC1155Function.Info = [info]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of AutoSwapRetrieveERC20ToERC1155Function)(autoSwapRetrieveERC20ToERC1155Function, cancellationToken)
        
        End Function
        Public Function GetRoleAdminQueryAsync(ByVal getRoleAdminFunction As GetRoleAdminFunction, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Byte())
        
            Return ContractHandler.QueryAsync(Of GetRoleAdminFunction, Byte())(getRoleAdminFunction, blockParameter)
        
        End Function

        
        Public Function GetRoleAdminQueryAsync(ByVal [role] As Byte(), ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Byte())
        
            Dim getRoleAdminFunction = New GetRoleAdminFunction()
                getRoleAdminFunction.Role = [role]
            
            Return ContractHandler.QueryAsync(Of GetRoleAdminFunction, Byte())(getRoleAdminFunction, blockParameter)
        
        End Function


        Public Function GetRoleMemberQueryAsync(ByVal getRoleMemberFunction As GetRoleMemberFunction, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of String)
        
            Return ContractHandler.QueryAsync(Of GetRoleMemberFunction, String)(getRoleMemberFunction, blockParameter)
        
        End Function

        
        Public Function GetRoleMemberQueryAsync(ByVal [role] As Byte(), ByVal [index] As BigInteger, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of String)
        
            Dim getRoleMemberFunction = New GetRoleMemberFunction()
                getRoleMemberFunction.Role = [role]
                getRoleMemberFunction.Index = [index]
            
            Return ContractHandler.QueryAsync(Of GetRoleMemberFunction, String)(getRoleMemberFunction, blockParameter)
        
        End Function


        Public Function GetRoleMemberCountQueryAsync(ByVal getRoleMemberCountFunction As GetRoleMemberCountFunction, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of BigInteger)
        
            Return ContractHandler.QueryAsync(Of GetRoleMemberCountFunction, BigInteger)(getRoleMemberCountFunction, blockParameter)
        
        End Function

        
        Public Function GetRoleMemberCountQueryAsync(ByVal [role] As Byte(), ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of BigInteger)
        
            Dim getRoleMemberCountFunction = New GetRoleMemberCountFunction()
                getRoleMemberCountFunction.Role = [role]
            
            Return ContractHandler.QueryAsync(Of GetRoleMemberCountFunction, BigInteger)(getRoleMemberCountFunction, blockParameter)
        
        End Function


        Public Function GrantRoleRequestAsync(ByVal grantRoleFunction As GrantRoleFunction) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of GrantRoleFunction)(grantRoleFunction)
        
        End Function

        Public Function GrantRoleRequestAndWaitForReceiptAsync(ByVal grantRoleFunction As GrantRoleFunction, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of GrantRoleFunction)(grantRoleFunction, cancellationToken)
        
        End Function

        
        Public Function GrantRoleRequestAsync(ByVal [role] As Byte(), ByVal [account] As String) As Task(Of String)
        
            Dim grantRoleFunction = New GrantRoleFunction()
                grantRoleFunction.Role = [role]
                grantRoleFunction.Account = [account]
            
            Return ContractHandler.SendRequestAsync(Of GrantRoleFunction)(grantRoleFunction)
        
        End Function

        
        Public Function GrantRoleRequestAndWaitForReceiptAsync(ByVal [role] As Byte(), ByVal [account] As String, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim grantRoleFunction = New GrantRoleFunction()
                grantRoleFunction.Role = [role]
                grantRoleFunction.Account = [account]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of GrantRoleFunction)(grantRoleFunction, cancellationToken)
        
        End Function
        Public Function HasRoleQueryAsync(ByVal hasRoleFunction As HasRoleFunction, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Boolean)
        
            Return ContractHandler.QueryAsync(Of HasRoleFunction, Boolean)(hasRoleFunction, blockParameter)
        
        End Function

        
        Public Function HasRoleQueryAsync(ByVal [role] As Byte(), ByVal [account] As String, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Boolean)
        
            Dim hasRoleFunction = New HasRoleFunction()
                hasRoleFunction.Role = [role]
                hasRoleFunction.Account = [account]
            
            Return ContractHandler.QueryAsync(Of HasRoleFunction, Boolean)(hasRoleFunction, blockParameter)
        
        End Function


        Public Function HiddenBatchERC1155SwapDepositRequestAsync(ByVal hiddenBatchERC1155SwapDepositFunction As HiddenBatchERC1155SwapDepositFunction) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of HiddenBatchERC1155SwapDepositFunction)(hiddenBatchERC1155SwapDepositFunction)
        
        End Function

        Public Function HiddenBatchERC1155SwapDepositRequestAndWaitForReceiptAsync(ByVal hiddenBatchERC1155SwapDepositFunction As HiddenBatchERC1155SwapDepositFunction, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenBatchERC1155SwapDepositFunction)(hiddenBatchERC1155SwapDepositFunction, cancellationToken)
        
        End Function

        
        Public Function HiddenBatchERC1155SwapDepositRequestAsync(ByVal [id1] As Byte()) As Task(Of String)
        
            Dim hiddenBatchERC1155SwapDepositFunction = New HiddenBatchERC1155SwapDepositFunction()
                hiddenBatchERC1155SwapDepositFunction.Id1 = [id1]
            
            Return ContractHandler.SendRequestAsync(Of HiddenBatchERC1155SwapDepositFunction)(hiddenBatchERC1155SwapDepositFunction)
        
        End Function

        
        Public Function HiddenBatchERC1155SwapDepositRequestAndWaitForReceiptAsync(ByVal [id1] As Byte(), ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim hiddenBatchERC1155SwapDepositFunction = New HiddenBatchERC1155SwapDepositFunction()
                hiddenBatchERC1155SwapDepositFunction.Id1 = [id1]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenBatchERC1155SwapDepositFunction)(hiddenBatchERC1155SwapDepositFunction, cancellationToken)
        
        End Function
        Public Function HiddenBatchERC1155SwapRetrieveRequestAsync(ByVal hiddenBatchERC1155SwapRetrieveFunction As HiddenBatchERC1155SwapRetrieveFunction) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of HiddenBatchERC1155SwapRetrieveFunction)(hiddenBatchERC1155SwapRetrieveFunction)
        
        End Function

        Public Function HiddenBatchERC1155SwapRetrieveRequestAndWaitForReceiptAsync(ByVal hiddenBatchERC1155SwapRetrieveFunction As HiddenBatchERC1155SwapRetrieveFunction, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenBatchERC1155SwapRetrieveFunction)(hiddenBatchERC1155SwapRetrieveFunction, cancellationToken)
        
        End Function

        
        Public Function HiddenBatchERC1155SwapRetrieveRequestAsync(ByVal [id1] As Byte(), ByVal [value] As BigInteger) As Task(Of String)
        
            Dim hiddenBatchERC1155SwapRetrieveFunction = New HiddenBatchERC1155SwapRetrieveFunction()
                hiddenBatchERC1155SwapRetrieveFunction.Id1 = [id1]
                hiddenBatchERC1155SwapRetrieveFunction.Value = [value]
            
            Return ContractHandler.SendRequestAsync(Of HiddenBatchERC1155SwapRetrieveFunction)(hiddenBatchERC1155SwapRetrieveFunction)
        
        End Function

        
        Public Function HiddenBatchERC1155SwapRetrieveRequestAndWaitForReceiptAsync(ByVal [id1] As Byte(), ByVal [value] As BigInteger, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim hiddenBatchERC1155SwapRetrieveFunction = New HiddenBatchERC1155SwapRetrieveFunction()
                hiddenBatchERC1155SwapRetrieveFunction.Id1 = [id1]
                hiddenBatchERC1155SwapRetrieveFunction.Value = [value]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenBatchERC1155SwapRetrieveFunction)(hiddenBatchERC1155SwapRetrieveFunction, cancellationToken)
        
        End Function
        Public Function HiddenBatchERC1155ToERC20SwapDepositRequestAsync(ByVal hiddenBatchERC1155ToERC20SwapDepositFunction As HiddenBatchERC1155ToERC20SwapDepositFunction) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of HiddenBatchERC1155ToERC20SwapDepositFunction)(hiddenBatchERC1155ToERC20SwapDepositFunction)
        
        End Function

        Public Function HiddenBatchERC1155ToERC20SwapDepositRequestAndWaitForReceiptAsync(ByVal hiddenBatchERC1155ToERC20SwapDepositFunction As HiddenBatchERC1155ToERC20SwapDepositFunction, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenBatchERC1155ToERC20SwapDepositFunction)(hiddenBatchERC1155ToERC20SwapDepositFunction, cancellationToken)
        
        End Function

        
        Public Function HiddenBatchERC1155ToERC20SwapDepositRequestAsync(ByVal [id1] As Byte()) As Task(Of String)
        
            Dim hiddenBatchERC1155ToERC20SwapDepositFunction = New HiddenBatchERC1155ToERC20SwapDepositFunction()
                hiddenBatchERC1155ToERC20SwapDepositFunction.Id1 = [id1]
            
            Return ContractHandler.SendRequestAsync(Of HiddenBatchERC1155ToERC20SwapDepositFunction)(hiddenBatchERC1155ToERC20SwapDepositFunction)
        
        End Function

        
        Public Function HiddenBatchERC1155ToERC20SwapDepositRequestAndWaitForReceiptAsync(ByVal [id1] As Byte(), ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim hiddenBatchERC1155ToERC20SwapDepositFunction = New HiddenBatchERC1155ToERC20SwapDepositFunction()
                hiddenBatchERC1155ToERC20SwapDepositFunction.Id1 = [id1]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenBatchERC1155ToERC20SwapDepositFunction)(hiddenBatchERC1155ToERC20SwapDepositFunction, cancellationToken)
        
        End Function
        Public Function HiddenBatchERC1155ToERC20SwapRetrieveRequestAsync(ByVal hiddenBatchERC1155ToERC20SwapRetrieveFunction As HiddenBatchERC1155ToERC20SwapRetrieveFunction) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of HiddenBatchERC1155ToERC20SwapRetrieveFunction)(hiddenBatchERC1155ToERC20SwapRetrieveFunction)
        
        End Function

        Public Function HiddenBatchERC1155ToERC20SwapRetrieveRequestAndWaitForReceiptAsync(ByVal hiddenBatchERC1155ToERC20SwapRetrieveFunction As HiddenBatchERC1155ToERC20SwapRetrieveFunction, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenBatchERC1155ToERC20SwapRetrieveFunction)(hiddenBatchERC1155ToERC20SwapRetrieveFunction, cancellationToken)
        
        End Function

        
        Public Function HiddenBatchERC1155ToERC20SwapRetrieveRequestAsync(ByVal [id1] As Byte(), ByVal [value] As BigInteger) As Task(Of String)
        
            Dim hiddenBatchERC1155ToERC20SwapRetrieveFunction = New HiddenBatchERC1155ToERC20SwapRetrieveFunction()
                hiddenBatchERC1155ToERC20SwapRetrieveFunction.Id1 = [id1]
                hiddenBatchERC1155ToERC20SwapRetrieveFunction.Value = [value]
            
            Return ContractHandler.SendRequestAsync(Of HiddenBatchERC1155ToERC20SwapRetrieveFunction)(hiddenBatchERC1155ToERC20SwapRetrieveFunction)
        
        End Function

        
        Public Function HiddenBatchERC1155ToERC20SwapRetrieveRequestAndWaitForReceiptAsync(ByVal [id1] As Byte(), ByVal [value] As BigInteger, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim hiddenBatchERC1155ToERC20SwapRetrieveFunction = New HiddenBatchERC1155ToERC20SwapRetrieveFunction()
                hiddenBatchERC1155ToERC20SwapRetrieveFunction.Id1 = [id1]
                hiddenBatchERC1155ToERC20SwapRetrieveFunction.Value = [value]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenBatchERC1155ToERC20SwapRetrieveFunction)(hiddenBatchERC1155ToERC20SwapRetrieveFunction, cancellationToken)
        
        End Function
        Public Function HiddenERC1155TimedSwapDepositRequestAsync(ByVal hiddenERC1155TimedSwapDepositFunction As HiddenERC1155TimedSwapDepositFunction) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of HiddenERC1155TimedSwapDepositFunction)(hiddenERC1155TimedSwapDepositFunction)
        
        End Function

        Public Function HiddenERC1155TimedSwapDepositRequestAndWaitForReceiptAsync(ByVal hiddenERC1155TimedSwapDepositFunction As HiddenERC1155TimedSwapDepositFunction, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenERC1155TimedSwapDepositFunction)(hiddenERC1155TimedSwapDepositFunction, cancellationToken)
        
        End Function

        
        Public Function HiddenERC1155TimedSwapDepositRequestAsync(ByVal [id1] As Byte(), ByVal [availableAt] As ULong, ByVal [expiresAt] As ULong, ByVal [autoRetrieveFees] As BigInteger) As Task(Of String)
        
            Dim hiddenERC1155TimedSwapDepositFunction = New HiddenERC1155TimedSwapDepositFunction()
                hiddenERC1155TimedSwapDepositFunction.Id1 = [id1]
                hiddenERC1155TimedSwapDepositFunction.AvailableAt = [availableAt]
                hiddenERC1155TimedSwapDepositFunction.ExpiresAt = [expiresAt]
                hiddenERC1155TimedSwapDepositFunction.AutoRetrieveFees = [autoRetrieveFees]
            
            Return ContractHandler.SendRequestAsync(Of HiddenERC1155TimedSwapDepositFunction)(hiddenERC1155TimedSwapDepositFunction)
        
        End Function

        
        Public Function HiddenERC1155TimedSwapDepositRequestAndWaitForReceiptAsync(ByVal [id1] As Byte(), ByVal [availableAt] As ULong, ByVal [expiresAt] As ULong, ByVal [autoRetrieveFees] As BigInteger, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim hiddenERC1155TimedSwapDepositFunction = New HiddenERC1155TimedSwapDepositFunction()
                hiddenERC1155TimedSwapDepositFunction.Id1 = [id1]
                hiddenERC1155TimedSwapDepositFunction.AvailableAt = [availableAt]
                hiddenERC1155TimedSwapDepositFunction.ExpiresAt = [expiresAt]
                hiddenERC1155TimedSwapDepositFunction.AutoRetrieveFees = [autoRetrieveFees]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenERC1155TimedSwapDepositFunction)(hiddenERC1155TimedSwapDepositFunction, cancellationToken)
        
        End Function
        Public Function HiddenERC1155ToERC20TimedSwapDepositRequestAsync(ByVal hiddenERC1155ToERC20TimedSwapDepositFunction As HiddenERC1155ToERC20TimedSwapDepositFunction) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of HiddenERC1155ToERC20TimedSwapDepositFunction)(hiddenERC1155ToERC20TimedSwapDepositFunction)
        
        End Function

        Public Function HiddenERC1155ToERC20TimedSwapDepositRequestAndWaitForReceiptAsync(ByVal hiddenERC1155ToERC20TimedSwapDepositFunction As HiddenERC1155ToERC20TimedSwapDepositFunction, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenERC1155ToERC20TimedSwapDepositFunction)(hiddenERC1155ToERC20TimedSwapDepositFunction, cancellationToken)
        
        End Function

        
        Public Function HiddenERC1155ToERC20TimedSwapDepositRequestAsync(ByVal [id1] As Byte(), ByVal [availableAt] As ULong, ByVal [expiresAt] As ULong, ByVal [autoRetrieveFees] As BigInteger) As Task(Of String)
        
            Dim hiddenERC1155ToERC20TimedSwapDepositFunction = New HiddenERC1155ToERC20TimedSwapDepositFunction()
                hiddenERC1155ToERC20TimedSwapDepositFunction.Id1 = [id1]
                hiddenERC1155ToERC20TimedSwapDepositFunction.AvailableAt = [availableAt]
                hiddenERC1155ToERC20TimedSwapDepositFunction.ExpiresAt = [expiresAt]
                hiddenERC1155ToERC20TimedSwapDepositFunction.AutoRetrieveFees = [autoRetrieveFees]
            
            Return ContractHandler.SendRequestAsync(Of HiddenERC1155ToERC20TimedSwapDepositFunction)(hiddenERC1155ToERC20TimedSwapDepositFunction)
        
        End Function

        
        Public Function HiddenERC1155ToERC20TimedSwapDepositRequestAndWaitForReceiptAsync(ByVal [id1] As Byte(), ByVal [availableAt] As ULong, ByVal [expiresAt] As ULong, ByVal [autoRetrieveFees] As BigInteger, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim hiddenERC1155ToERC20TimedSwapDepositFunction = New HiddenERC1155ToERC20TimedSwapDepositFunction()
                hiddenERC1155ToERC20TimedSwapDepositFunction.Id1 = [id1]
                hiddenERC1155ToERC20TimedSwapDepositFunction.AvailableAt = [availableAt]
                hiddenERC1155ToERC20TimedSwapDepositFunction.ExpiresAt = [expiresAt]
                hiddenERC1155ToERC20TimedSwapDepositFunction.AutoRetrieveFees = [autoRetrieveFees]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenERC1155ToERC20TimedSwapDepositFunction)(hiddenERC1155ToERC20TimedSwapDepositFunction, cancellationToken)
        
        End Function
        Public Function HiddenERC20ToBatchERC1155SwapDepositRequestAsync(ByVal hiddenERC20ToBatchERC1155SwapDepositFunction As HiddenERC20ToBatchERC1155SwapDepositFunction) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of HiddenERC20ToBatchERC1155SwapDepositFunction)(hiddenERC20ToBatchERC1155SwapDepositFunction)
        
        End Function

        Public Function HiddenERC20ToBatchERC1155SwapDepositRequestAndWaitForReceiptAsync(ByVal hiddenERC20ToBatchERC1155SwapDepositFunction As HiddenERC20ToBatchERC1155SwapDepositFunction, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenERC20ToBatchERC1155SwapDepositFunction)(hiddenERC20ToBatchERC1155SwapDepositFunction, cancellationToken)
        
        End Function

        
        Public Function HiddenERC20ToBatchERC1155SwapDepositRequestAsync(ByVal [id1] As Byte()) As Task(Of String)
        
            Dim hiddenERC20ToBatchERC1155SwapDepositFunction = New HiddenERC20ToBatchERC1155SwapDepositFunction()
                hiddenERC20ToBatchERC1155SwapDepositFunction.Id1 = [id1]
            
            Return ContractHandler.SendRequestAsync(Of HiddenERC20ToBatchERC1155SwapDepositFunction)(hiddenERC20ToBatchERC1155SwapDepositFunction)
        
        End Function

        
        Public Function HiddenERC20ToBatchERC1155SwapDepositRequestAndWaitForReceiptAsync(ByVal [id1] As Byte(), ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim hiddenERC20ToBatchERC1155SwapDepositFunction = New HiddenERC20ToBatchERC1155SwapDepositFunction()
                hiddenERC20ToBatchERC1155SwapDepositFunction.Id1 = [id1]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenERC20ToBatchERC1155SwapDepositFunction)(hiddenERC20ToBatchERC1155SwapDepositFunction, cancellationToken)
        
        End Function
        Public Function HiddenERC20ToBatchERC1155SwapRetrieveRequestAsync(ByVal hiddenERC20ToBatchERC1155SwapRetrieveFunction As HiddenERC20ToBatchERC1155SwapRetrieveFunction) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of HiddenERC20ToBatchERC1155SwapRetrieveFunction)(hiddenERC20ToBatchERC1155SwapRetrieveFunction)
        
        End Function

        Public Function HiddenERC20ToBatchERC1155SwapRetrieveRequestAndWaitForReceiptAsync(ByVal hiddenERC20ToBatchERC1155SwapRetrieveFunction As HiddenERC20ToBatchERC1155SwapRetrieveFunction, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenERC20ToBatchERC1155SwapRetrieveFunction)(hiddenERC20ToBatchERC1155SwapRetrieveFunction, cancellationToken)
        
        End Function

        
        Public Function HiddenERC20ToBatchERC1155SwapRetrieveRequestAsync(ByVal [id1] As Byte(), ByVal [value] As BigInteger) As Task(Of String)
        
            Dim hiddenERC20ToBatchERC1155SwapRetrieveFunction = New HiddenERC20ToBatchERC1155SwapRetrieveFunction()
                hiddenERC20ToBatchERC1155SwapRetrieveFunction.Id1 = [id1]
                hiddenERC20ToBatchERC1155SwapRetrieveFunction.Value = [value]
            
            Return ContractHandler.SendRequestAsync(Of HiddenERC20ToBatchERC1155SwapRetrieveFunction)(hiddenERC20ToBatchERC1155SwapRetrieveFunction)
        
        End Function

        
        Public Function HiddenERC20ToBatchERC1155SwapRetrieveRequestAndWaitForReceiptAsync(ByVal [id1] As Byte(), ByVal [value] As BigInteger, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim hiddenERC20ToBatchERC1155SwapRetrieveFunction = New HiddenERC20ToBatchERC1155SwapRetrieveFunction()
                hiddenERC20ToBatchERC1155SwapRetrieveFunction.Id1 = [id1]
                hiddenERC20ToBatchERC1155SwapRetrieveFunction.Value = [value]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenERC20ToBatchERC1155SwapRetrieveFunction)(hiddenERC20ToBatchERC1155SwapRetrieveFunction, cancellationToken)
        
        End Function
        Public Function HiddenERC20ToERC1155TimedSwapDepositRequestAsync(ByVal hiddenERC20ToERC1155TimedSwapDepositFunction As HiddenERC20ToERC1155TimedSwapDepositFunction) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of HiddenERC20ToERC1155TimedSwapDepositFunction)(hiddenERC20ToERC1155TimedSwapDepositFunction)
        
        End Function

        Public Function HiddenERC20ToERC1155TimedSwapDepositRequestAndWaitForReceiptAsync(ByVal hiddenERC20ToERC1155TimedSwapDepositFunction As HiddenERC20ToERC1155TimedSwapDepositFunction, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenERC20ToERC1155TimedSwapDepositFunction)(hiddenERC20ToERC1155TimedSwapDepositFunction, cancellationToken)
        
        End Function

        
        Public Function HiddenERC20ToERC1155TimedSwapDepositRequestAsync(ByVal [id1] As Byte(), ByVal [availableAt] As ULong, ByVal [expiresAt] As ULong, ByVal [autoRetrieveFees] As BigInteger) As Task(Of String)
        
            Dim hiddenERC20ToERC1155TimedSwapDepositFunction = New HiddenERC20ToERC1155TimedSwapDepositFunction()
                hiddenERC20ToERC1155TimedSwapDepositFunction.Id1 = [id1]
                hiddenERC20ToERC1155TimedSwapDepositFunction.AvailableAt = [availableAt]
                hiddenERC20ToERC1155TimedSwapDepositFunction.ExpiresAt = [expiresAt]
                hiddenERC20ToERC1155TimedSwapDepositFunction.AutoRetrieveFees = [autoRetrieveFees]
            
            Return ContractHandler.SendRequestAsync(Of HiddenERC20ToERC1155TimedSwapDepositFunction)(hiddenERC20ToERC1155TimedSwapDepositFunction)
        
        End Function

        
        Public Function HiddenERC20ToERC1155TimedSwapDepositRequestAndWaitForReceiptAsync(ByVal [id1] As Byte(), ByVal [availableAt] As ULong, ByVal [expiresAt] As ULong, ByVal [autoRetrieveFees] As BigInteger, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim hiddenERC20ToERC1155TimedSwapDepositFunction = New HiddenERC20ToERC1155TimedSwapDepositFunction()
                hiddenERC20ToERC1155TimedSwapDepositFunction.Id1 = [id1]
                hiddenERC20ToERC1155TimedSwapDepositFunction.AvailableAt = [availableAt]
                hiddenERC20ToERC1155TimedSwapDepositFunction.ExpiresAt = [expiresAt]
                hiddenERC20ToERC1155TimedSwapDepositFunction.AutoRetrieveFees = [autoRetrieveFees]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenERC20ToERC1155TimedSwapDepositFunction)(hiddenERC20ToERC1155TimedSwapDepositFunction, cancellationToken)
        
        End Function
        Public Function HiddenSwapERC1155RequestAsync(ByVal hiddenSwapERC1155Function As HiddenSwapERC1155Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of HiddenSwapERC1155Function)(hiddenSwapERC1155Function)
        
        End Function

        Public Function HiddenSwapERC1155RequestAndWaitForReceiptAsync(ByVal hiddenSwapERC1155Function As HiddenSwapERC1155Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenSwapERC1155Function)(hiddenSwapERC1155Function, cancellationToken)
        
        End Function

        
        Public Function HiddenSwapERC1155RequestAsync(ByVal [from] As String, ByVal [info] As SwapERC1155Info, ByVal [secret] As Byte()) As Task(Of String)
        
            Dim hiddenSwapERC1155Function = New HiddenSwapERC1155Function()
                hiddenSwapERC1155Function.From = [from]
                hiddenSwapERC1155Function.Info = [info]
                hiddenSwapERC1155Function.Secret = [secret]
            
            Return ContractHandler.SendRequestAsync(Of HiddenSwapERC1155Function)(hiddenSwapERC1155Function)
        
        End Function

        
        Public Function HiddenSwapERC1155RequestAndWaitForReceiptAsync(ByVal [from] As String, ByVal [info] As SwapERC1155Info, ByVal [secret] As Byte(), ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim hiddenSwapERC1155Function = New HiddenSwapERC1155Function()
                hiddenSwapERC1155Function.From = [from]
                hiddenSwapERC1155Function.Info = [info]
                hiddenSwapERC1155Function.Secret = [secret]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenSwapERC1155Function)(hiddenSwapERC1155Function, cancellationToken)
        
        End Function
        Public Function HiddenSwapERC1155ToERC20RequestAsync(ByVal hiddenSwapERC1155ToERC20Function As HiddenSwapERC1155ToERC20Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of HiddenSwapERC1155ToERC20Function)(hiddenSwapERC1155ToERC20Function)
        
        End Function

        Public Function HiddenSwapERC1155ToERC20RequestAndWaitForReceiptAsync(ByVal hiddenSwapERC1155ToERC20Function As HiddenSwapERC1155ToERC20Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenSwapERC1155ToERC20Function)(hiddenSwapERC1155ToERC20Function, cancellationToken)
        
        End Function

        
        Public Function HiddenSwapERC1155ToERC20RequestAsync(ByVal [from] As String, ByVal [info] As SwapBatchERC1155ToERC20Info, ByVal [secret] As Byte()) As Task(Of String)
        
            Dim hiddenSwapERC1155ToERC20Function = New HiddenSwapERC1155ToERC20Function()
                hiddenSwapERC1155ToERC20Function.From = [from]
                hiddenSwapERC1155ToERC20Function.Info = [info]
                hiddenSwapERC1155ToERC20Function.Secret = [secret]
            
            Return ContractHandler.SendRequestAsync(Of HiddenSwapERC1155ToERC20Function)(hiddenSwapERC1155ToERC20Function)
        
        End Function

        
        Public Function HiddenSwapERC1155ToERC20RequestAndWaitForReceiptAsync(ByVal [from] As String, ByVal [info] As SwapBatchERC1155ToERC20Info, ByVal [secret] As Byte(), ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim hiddenSwapERC1155ToERC20Function = New HiddenSwapERC1155ToERC20Function()
                hiddenSwapERC1155ToERC20Function.From = [from]
                hiddenSwapERC1155ToERC20Function.Info = [info]
                hiddenSwapERC1155ToERC20Function.Secret = [secret]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenSwapERC1155ToERC20Function)(hiddenSwapERC1155ToERC20Function, cancellationToken)
        
        End Function
        Public Function HiddenSwapERC20ToERC1155RequestAsync(ByVal hiddenSwapERC20ToERC1155Function As HiddenSwapERC20ToERC1155Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of HiddenSwapERC20ToERC1155Function)(hiddenSwapERC20ToERC1155Function)
        
        End Function

        Public Function HiddenSwapERC20ToERC1155RequestAndWaitForReceiptAsync(ByVal hiddenSwapERC20ToERC1155Function As HiddenSwapERC20ToERC1155Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenSwapERC20ToERC1155Function)(hiddenSwapERC20ToERC1155Function, cancellationToken)
        
        End Function

        
        Public Function HiddenSwapERC20ToERC1155RequestAsync(ByVal [from] As String, ByVal [info] As SwapERC20ToBatchERC1155Info, ByVal [secret] As Byte()) As Task(Of String)
        
            Dim hiddenSwapERC20ToERC1155Function = New HiddenSwapERC20ToERC1155Function()
                hiddenSwapERC20ToERC1155Function.From = [from]
                hiddenSwapERC20ToERC1155Function.Info = [info]
                hiddenSwapERC20ToERC1155Function.Secret = [secret]
            
            Return ContractHandler.SendRequestAsync(Of HiddenSwapERC20ToERC1155Function)(hiddenSwapERC20ToERC1155Function)
        
        End Function

        
        Public Function HiddenSwapERC20ToERC1155RequestAndWaitForReceiptAsync(ByVal [from] As String, ByVal [info] As SwapERC20ToBatchERC1155Info, ByVal [secret] As Byte(), ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim hiddenSwapERC20ToERC1155Function = New HiddenSwapERC20ToERC1155Function()
                hiddenSwapERC20ToERC1155Function.From = [from]
                hiddenSwapERC20ToERC1155Function.Info = [info]
                hiddenSwapERC20ToERC1155Function.Secret = [secret]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of HiddenSwapERC20ToERC1155Function)(hiddenSwapERC20ToERC1155Function, cancellationToken)
        
        End Function
        Public Function RenounceRoleRequestAsync(ByVal renounceRoleFunction As RenounceRoleFunction) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of RenounceRoleFunction)(renounceRoleFunction)
        
        End Function

        Public Function RenounceRoleRequestAndWaitForReceiptAsync(ByVal renounceRoleFunction As RenounceRoleFunction, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of RenounceRoleFunction)(renounceRoleFunction, cancellationToken)
        
        End Function

        
        Public Function RenounceRoleRequestAsync(ByVal [role] As Byte(), ByVal [account] As String) As Task(Of String)
        
            Dim renounceRoleFunction = New RenounceRoleFunction()
                renounceRoleFunction.Role = [role]
                renounceRoleFunction.Account = [account]
            
            Return ContractHandler.SendRequestAsync(Of RenounceRoleFunction)(renounceRoleFunction)
        
        End Function

        
        Public Function RenounceRoleRequestAndWaitForReceiptAsync(ByVal [role] As Byte(), ByVal [account] As String, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim renounceRoleFunction = New RenounceRoleFunction()
                renounceRoleFunction.Role = [role]
                renounceRoleFunction.Account = [account]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of RenounceRoleFunction)(renounceRoleFunction, cancellationToken)
        
        End Function
        Public Function RevokeRoleRequestAsync(ByVal revokeRoleFunction As RevokeRoleFunction) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of RevokeRoleFunction)(revokeRoleFunction)
        
        End Function

        Public Function RevokeRoleRequestAndWaitForReceiptAsync(ByVal revokeRoleFunction As RevokeRoleFunction, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of RevokeRoleFunction)(revokeRoleFunction, cancellationToken)
        
        End Function

        
        Public Function RevokeRoleRequestAsync(ByVal [role] As Byte(), ByVal [account] As String) As Task(Of String)
        
            Dim revokeRoleFunction = New RevokeRoleFunction()
                revokeRoleFunction.Role = [role]
                revokeRoleFunction.Account = [account]
            
            Return ContractHandler.SendRequestAsync(Of RevokeRoleFunction)(revokeRoleFunction)
        
        End Function

        
        Public Function RevokeRoleRequestAndWaitForReceiptAsync(ByVal [role] As Byte(), ByVal [account] As String, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim revokeRoleFunction = New RevokeRoleFunction()
                revokeRoleFunction.Role = [role]
                revokeRoleFunction.Account = [account]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of RevokeRoleFunction)(revokeRoleFunction, cancellationToken)
        
        End Function
        Public Function SwapDepositERC1155RequestAsync(ByVal swapDepositERC1155Function As SwapDepositERC1155Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of SwapDepositERC1155Function)(swapDepositERC1155Function)
        
        End Function

        Public Function SwapDepositERC1155RequestAndWaitForReceiptAsync(ByVal swapDepositERC1155Function As SwapDepositERC1155Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapDepositERC1155Function)(swapDepositERC1155Function, cancellationToken)
        
        End Function

        
        Public Function SwapDepositERC1155RequestAsync(ByVal [to] As String, ByVal [info] As SwapERC1155Info) As Task(Of String)
        
            Dim swapDepositERC1155Function = New SwapDepositERC1155Function()
                swapDepositERC1155Function.To = [to]
                swapDepositERC1155Function.Info = [info]
            
            Return ContractHandler.SendRequestAsync(Of SwapDepositERC1155Function)(swapDepositERC1155Function)
        
        End Function

        
        Public Function SwapDepositERC1155RequestAndWaitForReceiptAsync(ByVal [to] As String, ByVal [info] As SwapERC1155Info, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim swapDepositERC1155Function = New SwapDepositERC1155Function()
                swapDepositERC1155Function.To = [to]
                swapDepositERC1155Function.Info = [info]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapDepositERC1155Function)(swapDepositERC1155Function, cancellationToken)
        
        End Function
        Public Function SwapDepositERC1155ToERC20RequestAsync(ByVal swapDepositERC1155ToERC20Function As SwapDepositERC1155ToERC20Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of SwapDepositERC1155ToERC20Function)(swapDepositERC1155ToERC20Function)
        
        End Function

        Public Function SwapDepositERC1155ToERC20RequestAndWaitForReceiptAsync(ByVal swapDepositERC1155ToERC20Function As SwapDepositERC1155ToERC20Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapDepositERC1155ToERC20Function)(swapDepositERC1155ToERC20Function, cancellationToken)
        
        End Function

        
        Public Function SwapDepositERC1155ToERC20RequestAsync(ByVal [to] As String, ByVal [info] As SwapBatchERC1155ToERC20Info) As Task(Of String)
        
            Dim swapDepositERC1155ToERC20Function = New SwapDepositERC1155ToERC20Function()
                swapDepositERC1155ToERC20Function.To = [to]
                swapDepositERC1155ToERC20Function.Info = [info]
            
            Return ContractHandler.SendRequestAsync(Of SwapDepositERC1155ToERC20Function)(swapDepositERC1155ToERC20Function)
        
        End Function

        
        Public Function SwapDepositERC1155ToERC20RequestAndWaitForReceiptAsync(ByVal [to] As String, ByVal [info] As SwapBatchERC1155ToERC20Info, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim swapDepositERC1155ToERC20Function = New SwapDepositERC1155ToERC20Function()
                swapDepositERC1155ToERC20Function.To = [to]
                swapDepositERC1155ToERC20Function.Info = [info]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapDepositERC1155ToERC20Function)(swapDepositERC1155ToERC20Function, cancellationToken)
        
        End Function
        Public Function SwapDepositERC20ToERC1155RequestAsync(ByVal swapDepositERC20ToERC1155Function As SwapDepositERC20ToERC1155Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of SwapDepositERC20ToERC1155Function)(swapDepositERC20ToERC1155Function)
        
        End Function

        Public Function SwapDepositERC20ToERC1155RequestAndWaitForReceiptAsync(ByVal swapDepositERC20ToERC1155Function As SwapDepositERC20ToERC1155Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapDepositERC20ToERC1155Function)(swapDepositERC20ToERC1155Function, cancellationToken)
        
        End Function

        
        Public Function SwapDepositERC20ToERC1155RequestAsync(ByVal [to] As String, ByVal [info] As SwapERC20ToBatchERC1155Info) As Task(Of String)
        
            Dim swapDepositERC20ToERC1155Function = New SwapDepositERC20ToERC1155Function()
                swapDepositERC20ToERC1155Function.To = [to]
                swapDepositERC20ToERC1155Function.Info = [info]
            
            Return ContractHandler.SendRequestAsync(Of SwapDepositERC20ToERC1155Function)(swapDepositERC20ToERC1155Function)
        
        End Function

        
        Public Function SwapDepositERC20ToERC1155RequestAndWaitForReceiptAsync(ByVal [to] As String, ByVal [info] As SwapERC20ToBatchERC1155Info, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim swapDepositERC20ToERC1155Function = New SwapDepositERC20ToERC1155Function()
                swapDepositERC20ToERC1155Function.To = [to]
                swapDepositERC20ToERC1155Function.Info = [info]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapDepositERC20ToERC1155Function)(swapDepositERC20ToERC1155Function, cancellationToken)
        
        End Function
        Public Function SwapERC1155RequestAsync(ByVal swapERC1155Function As SwapERC1155Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of SwapERC1155Function)(swapERC1155Function)
        
        End Function

        Public Function SwapERC1155RequestAndWaitForReceiptAsync(ByVal swapERC1155Function As SwapERC1155Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapERC1155Function)(swapERC1155Function, cancellationToken)
        
        End Function

        
        Public Function SwapERC1155RequestAsync(ByVal [from] As String, ByVal [info] As SwapERC1155Info, ByVal [secret] As Byte()) As Task(Of String)
        
            Dim swapERC1155Function = New SwapERC1155Function()
                swapERC1155Function.From = [from]
                swapERC1155Function.Info = [info]
                swapERC1155Function.Secret = [secret]
            
            Return ContractHandler.SendRequestAsync(Of SwapERC1155Function)(swapERC1155Function)
        
        End Function

        
        Public Function SwapERC1155RequestAndWaitForReceiptAsync(ByVal [from] As String, ByVal [info] As SwapERC1155Info, ByVal [secret] As Byte(), ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim swapERC1155Function = New SwapERC1155Function()
                swapERC1155Function.From = [from]
                swapERC1155Function.Info = [info]
                swapERC1155Function.Secret = [secret]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapERC1155Function)(swapERC1155Function, cancellationToken)
        
        End Function
        Public Function SwapERC1155ToERC20RequestAsync(ByVal swapERC1155ToERC20Function As SwapERC1155ToERC20Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of SwapERC1155ToERC20Function)(swapERC1155ToERC20Function)
        
        End Function

        Public Function SwapERC1155ToERC20RequestAndWaitForReceiptAsync(ByVal swapERC1155ToERC20Function As SwapERC1155ToERC20Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapERC1155ToERC20Function)(swapERC1155ToERC20Function, cancellationToken)
        
        End Function

        
        Public Function SwapERC1155ToERC20RequestAsync(ByVal [from] As String, ByVal [info] As SwapBatchERC1155ToERC20Info, ByVal [secret] As Byte()) As Task(Of String)
        
            Dim swapERC1155ToERC20Function = New SwapERC1155ToERC20Function()
                swapERC1155ToERC20Function.From = [from]
                swapERC1155ToERC20Function.Info = [info]
                swapERC1155ToERC20Function.Secret = [secret]
            
            Return ContractHandler.SendRequestAsync(Of SwapERC1155ToERC20Function)(swapERC1155ToERC20Function)
        
        End Function

        
        Public Function SwapERC1155ToERC20RequestAndWaitForReceiptAsync(ByVal [from] As String, ByVal [info] As SwapBatchERC1155ToERC20Info, ByVal [secret] As Byte(), ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim swapERC1155ToERC20Function = New SwapERC1155ToERC20Function()
                swapERC1155ToERC20Function.From = [from]
                swapERC1155ToERC20Function.Info = [info]
                swapERC1155ToERC20Function.Secret = [secret]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapERC1155ToERC20Function)(swapERC1155ToERC20Function, cancellationToken)
        
        End Function
        Public Function SwapERC20ToERC1155RequestAsync(ByVal swapERC20ToERC1155Function As SwapERC20ToERC1155Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of SwapERC20ToERC1155Function)(swapERC20ToERC1155Function)
        
        End Function

        Public Function SwapERC20ToERC1155RequestAndWaitForReceiptAsync(ByVal swapERC20ToERC1155Function As SwapERC20ToERC1155Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapERC20ToERC1155Function)(swapERC20ToERC1155Function, cancellationToken)
        
        End Function

        
        Public Function SwapERC20ToERC1155RequestAsync(ByVal [from] As String, ByVal [info] As SwapERC20ToBatchERC1155Info, ByVal [secret] As Byte()) As Task(Of String)
        
            Dim swapERC20ToERC1155Function = New SwapERC20ToERC1155Function()
                swapERC20ToERC1155Function.From = [from]
                swapERC20ToERC1155Function.Info = [info]
                swapERC20ToERC1155Function.Secret = [secret]
            
            Return ContractHandler.SendRequestAsync(Of SwapERC20ToERC1155Function)(swapERC20ToERC1155Function)
        
        End Function

        
        Public Function SwapERC20ToERC1155RequestAndWaitForReceiptAsync(ByVal [from] As String, ByVal [info] As SwapERC20ToBatchERC1155Info, ByVal [secret] As Byte(), ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim swapERC20ToERC1155Function = New SwapERC20ToERC1155Function()
                swapERC20ToERC1155Function.From = [from]
                swapERC20ToERC1155Function.Info = [info]
                swapERC20ToERC1155Function.Secret = [secret]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapERC20ToERC1155Function)(swapERC20ToERC1155Function, cancellationToken)
        
        End Function
        Public Function SwapRetrieveERC1155RequestAsync(ByVal swapRetrieveERC1155Function As SwapRetrieveERC1155Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of SwapRetrieveERC1155Function)(swapRetrieveERC1155Function)
        
        End Function

        Public Function SwapRetrieveERC1155RequestAndWaitForReceiptAsync(ByVal swapRetrieveERC1155Function As SwapRetrieveERC1155Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapRetrieveERC1155Function)(swapRetrieveERC1155Function, cancellationToken)
        
        End Function

        
        Public Function SwapRetrieveERC1155RequestAsync(ByVal [to] As String, ByVal [info] As SwapERC1155Info) As Task(Of String)
        
            Dim swapRetrieveERC1155Function = New SwapRetrieveERC1155Function()
                swapRetrieveERC1155Function.To = [to]
                swapRetrieveERC1155Function.Info = [info]
            
            Return ContractHandler.SendRequestAsync(Of SwapRetrieveERC1155Function)(swapRetrieveERC1155Function)
        
        End Function

        
        Public Function SwapRetrieveERC1155RequestAndWaitForReceiptAsync(ByVal [to] As String, ByVal [info] As SwapERC1155Info, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim swapRetrieveERC1155Function = New SwapRetrieveERC1155Function()
                swapRetrieveERC1155Function.To = [to]
                swapRetrieveERC1155Function.Info = [info]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapRetrieveERC1155Function)(swapRetrieveERC1155Function, cancellationToken)
        
        End Function
        Public Function SwapRetrieveERC1155ToERC20RequestAsync(ByVal swapRetrieveERC1155ToERC20Function As SwapRetrieveERC1155ToERC20Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of SwapRetrieveERC1155ToERC20Function)(swapRetrieveERC1155ToERC20Function)
        
        End Function

        Public Function SwapRetrieveERC1155ToERC20RequestAndWaitForReceiptAsync(ByVal swapRetrieveERC1155ToERC20Function As SwapRetrieveERC1155ToERC20Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapRetrieveERC1155ToERC20Function)(swapRetrieveERC1155ToERC20Function, cancellationToken)
        
        End Function

        
        Public Function SwapRetrieveERC1155ToERC20RequestAsync(ByVal [to] As String, ByVal [info] As SwapBatchERC1155ToERC20Info) As Task(Of String)
        
            Dim swapRetrieveERC1155ToERC20Function = New SwapRetrieveERC1155ToERC20Function()
                swapRetrieveERC1155ToERC20Function.To = [to]
                swapRetrieveERC1155ToERC20Function.Info = [info]
            
            Return ContractHandler.SendRequestAsync(Of SwapRetrieveERC1155ToERC20Function)(swapRetrieveERC1155ToERC20Function)
        
        End Function

        
        Public Function SwapRetrieveERC1155ToERC20RequestAndWaitForReceiptAsync(ByVal [to] As String, ByVal [info] As SwapBatchERC1155ToERC20Info, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim swapRetrieveERC1155ToERC20Function = New SwapRetrieveERC1155ToERC20Function()
                swapRetrieveERC1155ToERC20Function.To = [to]
                swapRetrieveERC1155ToERC20Function.Info = [info]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapRetrieveERC1155ToERC20Function)(swapRetrieveERC1155ToERC20Function, cancellationToken)
        
        End Function
        Public Function SwapRetrieveERC20ToERC1155RequestAsync(ByVal swapRetrieveERC20ToERC1155Function As SwapRetrieveERC20ToERC1155Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of SwapRetrieveERC20ToERC1155Function)(swapRetrieveERC20ToERC1155Function)
        
        End Function

        Public Function SwapRetrieveERC20ToERC1155RequestAndWaitForReceiptAsync(ByVal swapRetrieveERC20ToERC1155Function As SwapRetrieveERC20ToERC1155Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapRetrieveERC20ToERC1155Function)(swapRetrieveERC20ToERC1155Function, cancellationToken)
        
        End Function

        
        Public Function SwapRetrieveERC20ToERC1155RequestAsync(ByVal [to] As String, ByVal [info] As SwapERC20ToBatchERC1155Info) As Task(Of String)
        
            Dim swapRetrieveERC20ToERC1155Function = New SwapRetrieveERC20ToERC1155Function()
                swapRetrieveERC20ToERC1155Function.To = [to]
                swapRetrieveERC20ToERC1155Function.Info = [info]
            
            Return ContractHandler.SendRequestAsync(Of SwapRetrieveERC20ToERC1155Function)(swapRetrieveERC20ToERC1155Function)
        
        End Function

        
        Public Function SwapRetrieveERC20ToERC1155RequestAndWaitForReceiptAsync(ByVal [to] As String, ByVal [info] As SwapERC20ToBatchERC1155Info, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim swapRetrieveERC20ToERC1155Function = New SwapRetrieveERC20ToERC1155Function()
                swapRetrieveERC20ToERC1155Function.To = [to]
                swapRetrieveERC20ToERC1155Function.Info = [info]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of SwapRetrieveERC20ToERC1155Function)(swapRetrieveERC20ToERC1155Function, cancellationToken)
        
        End Function
        Public Function TimedSwapDepositERC1155RequestAsync(ByVal timedSwapDepositERC1155Function As TimedSwapDepositERC1155Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of TimedSwapDepositERC1155Function)(timedSwapDepositERC1155Function)
        
        End Function

        Public Function TimedSwapDepositERC1155RequestAndWaitForReceiptAsync(ByVal timedSwapDepositERC1155Function As TimedSwapDepositERC1155Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of TimedSwapDepositERC1155Function)(timedSwapDepositERC1155Function, cancellationToken)
        
        End Function

        
        Public Function TimedSwapDepositERC1155RequestAsync(ByVal [to] As String, ByVal [info] As SwapERC1155Info, ByVal [availableAt] As ULong, ByVal [expiresAt] As ULong, ByVal [autoRetrieveFees] As BigInteger) As Task(Of String)
        
            Dim timedSwapDepositERC1155Function = New TimedSwapDepositERC1155Function()
                timedSwapDepositERC1155Function.To = [to]
                timedSwapDepositERC1155Function.Info = [info]
                timedSwapDepositERC1155Function.AvailableAt = [availableAt]
                timedSwapDepositERC1155Function.ExpiresAt = [expiresAt]
                timedSwapDepositERC1155Function.AutoRetrieveFees = [autoRetrieveFees]
            
            Return ContractHandler.SendRequestAsync(Of TimedSwapDepositERC1155Function)(timedSwapDepositERC1155Function)
        
        End Function

        
        Public Function TimedSwapDepositERC1155RequestAndWaitForReceiptAsync(ByVal [to] As String, ByVal [info] As SwapERC1155Info, ByVal [availableAt] As ULong, ByVal [expiresAt] As ULong, ByVal [autoRetrieveFees] As BigInteger, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim timedSwapDepositERC1155Function = New TimedSwapDepositERC1155Function()
                timedSwapDepositERC1155Function.To = [to]
                timedSwapDepositERC1155Function.Info = [info]
                timedSwapDepositERC1155Function.AvailableAt = [availableAt]
                timedSwapDepositERC1155Function.ExpiresAt = [expiresAt]
                timedSwapDepositERC1155Function.AutoRetrieveFees = [autoRetrieveFees]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of TimedSwapDepositERC1155Function)(timedSwapDepositERC1155Function, cancellationToken)
        
        End Function
        Public Function TimedSwapDepositERC1155ToERC20RequestAsync(ByVal timedSwapDepositERC1155ToERC20Function As TimedSwapDepositERC1155ToERC20Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of TimedSwapDepositERC1155ToERC20Function)(timedSwapDepositERC1155ToERC20Function)
        
        End Function

        Public Function TimedSwapDepositERC1155ToERC20RequestAndWaitForReceiptAsync(ByVal timedSwapDepositERC1155ToERC20Function As TimedSwapDepositERC1155ToERC20Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of TimedSwapDepositERC1155ToERC20Function)(timedSwapDepositERC1155ToERC20Function, cancellationToken)
        
        End Function

        
        Public Function TimedSwapDepositERC1155ToERC20RequestAsync(ByVal [to] As String, ByVal [info] As SwapBatchERC1155ToERC20Info, ByVal [availableAt] As ULong, ByVal [expiresAt] As ULong, ByVal [autoRetrieveFees] As BigInteger) As Task(Of String)
        
            Dim timedSwapDepositERC1155ToERC20Function = New TimedSwapDepositERC1155ToERC20Function()
                timedSwapDepositERC1155ToERC20Function.To = [to]
                timedSwapDepositERC1155ToERC20Function.Info = [info]
                timedSwapDepositERC1155ToERC20Function.AvailableAt = [availableAt]
                timedSwapDepositERC1155ToERC20Function.ExpiresAt = [expiresAt]
                timedSwapDepositERC1155ToERC20Function.AutoRetrieveFees = [autoRetrieveFees]
            
            Return ContractHandler.SendRequestAsync(Of TimedSwapDepositERC1155ToERC20Function)(timedSwapDepositERC1155ToERC20Function)
        
        End Function

        
        Public Function TimedSwapDepositERC1155ToERC20RequestAndWaitForReceiptAsync(ByVal [to] As String, ByVal [info] As SwapBatchERC1155ToERC20Info, ByVal [availableAt] As ULong, ByVal [expiresAt] As ULong, ByVal [autoRetrieveFees] As BigInteger, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim timedSwapDepositERC1155ToERC20Function = New TimedSwapDepositERC1155ToERC20Function()
                timedSwapDepositERC1155ToERC20Function.To = [to]
                timedSwapDepositERC1155ToERC20Function.Info = [info]
                timedSwapDepositERC1155ToERC20Function.AvailableAt = [availableAt]
                timedSwapDepositERC1155ToERC20Function.ExpiresAt = [expiresAt]
                timedSwapDepositERC1155ToERC20Function.AutoRetrieveFees = [autoRetrieveFees]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of TimedSwapDepositERC1155ToERC20Function)(timedSwapDepositERC1155ToERC20Function, cancellationToken)
        
        End Function
        Public Function TimedSwapDepositERC20ToERC1155RequestAsync(ByVal timedSwapDepositERC20ToERC1155Function As TimedSwapDepositERC20ToERC1155Function) As Task(Of String)
                    
            Return ContractHandler.SendRequestAsync(Of TimedSwapDepositERC20ToERC1155Function)(timedSwapDepositERC20ToERC1155Function)
        
        End Function

        Public Function TimedSwapDepositERC20ToERC1155RequestAndWaitForReceiptAsync(ByVal timedSwapDepositERC20ToERC1155Function As TimedSwapDepositERC20ToERC1155Function, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of TimedSwapDepositERC20ToERC1155Function)(timedSwapDepositERC20ToERC1155Function, cancellationToken)
        
        End Function

        
        Public Function TimedSwapDepositERC20ToERC1155RequestAsync(ByVal [to] As String, ByVal [info] As SwapERC20ToBatchERC1155Info, ByVal [availableAt] As ULong, ByVal [expiresAt] As ULong, ByVal [autoRetrieveFees] As BigInteger) As Task(Of String)
        
            Dim timedSwapDepositERC20ToERC1155Function = New TimedSwapDepositERC20ToERC1155Function()
                timedSwapDepositERC20ToERC1155Function.To = [to]
                timedSwapDepositERC20ToERC1155Function.Info = [info]
                timedSwapDepositERC20ToERC1155Function.AvailableAt = [availableAt]
                timedSwapDepositERC20ToERC1155Function.ExpiresAt = [expiresAt]
                timedSwapDepositERC20ToERC1155Function.AutoRetrieveFees = [autoRetrieveFees]
            
            Return ContractHandler.SendRequestAsync(Of TimedSwapDepositERC20ToERC1155Function)(timedSwapDepositERC20ToERC1155Function)
        
        End Function

        
        Public Function TimedSwapDepositERC20ToERC1155RequestAndWaitForReceiptAsync(ByVal [to] As String, ByVal [info] As SwapERC20ToBatchERC1155Info, ByVal [availableAt] As ULong, ByVal [expiresAt] As ULong, ByVal [autoRetrieveFees] As BigInteger, ByVal Optional cancellationToken As CancellationTokenSource = Nothing) As Task(Of TransactionReceipt)
        
            Dim timedSwapDepositERC20ToERC1155Function = New TimedSwapDepositERC20ToERC1155Function()
                timedSwapDepositERC20ToERC1155Function.To = [to]
                timedSwapDepositERC20ToERC1155Function.Info = [info]
                timedSwapDepositERC20ToERC1155Function.AvailableAt = [availableAt]
                timedSwapDepositERC20ToERC1155Function.ExpiresAt = [expiresAt]
                timedSwapDepositERC20ToERC1155Function.AutoRetrieveFees = [autoRetrieveFees]
            
            Return ContractHandler.SendRequestAndWaitForReceiptAsync(Of TimedSwapDepositERC20ToERC1155Function)(timedSwapDepositERC20ToERC1155Function, cancellationToken)
        
        End Function
        Public Function TotalFeesQueryAsync(ByVal totalFeesFunction As TotalFeesFunction, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of BigInteger)
        
            Return ContractHandler.QueryAsync(Of TotalFeesFunction, BigInteger)(totalFeesFunction, blockParameter)
        
        End Function

        
        Public Function TotalFeesQueryAsync(ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of BigInteger)
        
            return ContractHandler.QueryAsync(Of TotalFeesFunction, BigInteger)(Nothing, blockParameter)
        
        End Function



        Public Function UidQueryAsync(ByVal uidFunction As UidFunction, ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Byte())
        
            Return ContractHandler.QueryAsync(Of UidFunction, Byte())(uidFunction, blockParameter)
        
        End Function

        
        Public Function UidQueryAsync(ByVal Optional blockParameter As BlockParameter = Nothing) As Task(Of Byte())
        
            return ContractHandler.QueryAsync(Of UidFunction, Byte())(Nothing, blockParameter)
        
        End Function



    
    End Class

End Namespace

[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $CmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\Microsoft365.psm1" `
            -Resolve)
)

$GenericStubPath = (Join-Path -Path $PSScriptRoot `
        -ChildPath "..\Stubs\Generic.psm1" `
        -Resolve)
Import-Module -Name (Join-Path -Path $PSScriptRoot `
        -ChildPath "..\UnitTestHelper.psm1" `
        -Resolve)

$Global:DscHelper = New-M365DscUnitTestHelper -StubModule $CmdletModule `
    -DscResource "EXOAddressBookPolicy" -GenericStubModule $GenericStubPath
Describe -Name $Global:DscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:DscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:DscHelper.InitializeScript -NoNewScope

        $secpasswd = ConvertTo-SecureString "test@password1" -AsPlainText -Force
        $GlobalAdminAccount = New-Object System.Management.Automation.PSCredential ("tenantadmin", $secpasswd)

        Mock -CommandName Close-SessionsAndReturnError -MockWith {

        }

        Mock -CommandName Test-MSCloudLogin -MockWith {

        }

        Mock -CommandName Get-PSSession -MockWith {

        }

        Mock -CommandName Remove-PSSession -MockWith {

        }

        # Test contexts
        Context -Name "Address Book Policy should exist. Address Book Policy is missing. Test should fail." -Fixture {
            $testParams = @{
                Name               = "Contoso ABP"
                AddressLists       = "\All Contoso"
                GlobalAddressList  = "\All Contoso"
                OfflineAddressBook = "\Contoso-All-OAB"
                RoomList           = "\All Contoso-Rooms"
                Ensure             = 'Present'
                GlobalAdminAccount = $GlobalAdminAccount
            }

            Mock -CommandName Get-AddressBookPolicy -MockWith {
                return @{
                    Name                = "Contoso Different ABP"
                    AddressLists        = "\All Contoso"
                    GlobalAddressList   = "\All Contoso"
                    OfflineAddressBook  = "\Contoso-All-OAB"
                    RoomList            = "\All Contoso-Rooms"
                    FreeBusyAccessLevel = 'AvailabilityOnly'
                }
            }

            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should Be $false
            }

            Mock -CommandName Set-AddressBookPolicy -MockWith {
                return @{
                    Name               = "Contoso ABP"
                    AddressLists       = "\All Contoso"
                    GlobalAddressList  = "\All Contoso"
                    OfflineAddressBook = "\Contoso-All-OAB"
                    RoomList           = "\All Contoso-Rooms"
                    Ensure             = 'Present'
                    GlobalAdminAccount = $GlobalAdminAccount
                }
            }

            It "Should call the Set method" {
                Set-TargetResource @testParams
            }

            It "Should return Absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }
        }

        Context -Name "Address Book Policy should exist. Address Book Policy exists. Test should pass." -Fixture {
            $testParams = @{
                Name               = "Contoso ABP"
                AddressLists       = "\All Contoso"
                GlobalAddressList  = "\All Contoso"
                OfflineAddressBook = "\Contoso-All-OAB"
                RoomList           = "\All Contoso-Rooms"
                Ensure             = 'Present'
                GlobalAdminAccount = $GlobalAdminAccount
            }

            Mock -CommandName Get-AddressBookPolicy -MockWith {
                return @{
                    Name               = "Contoso ABP"
                    AddressLists       = "\All Contoso"
                    GlobalAddressList  = "\All Contoso"
                    OfflineAddressBook = "\Contoso-All-OAB"
                    RoomList           = "\All Contoso-Rooms"
                }
            }

            It 'Should return true from the Test method' {
                Test-TargetResource @testParams | Should Be $true
            }

            It 'Should return Present from the Get Method' {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }
        }

        Context -Name "Address Book Policy should exist. Address Book Policy exists, RoomList mismatch. Test should fail." -Fixture {
            $testParams = @{
                Name               = "Contoso ABP"
                AddressLists       = "\All Contoso"
                GlobalAddressList  = "\All Contoso"
                OfflineAddressBook = "\Contoso-All-OAB"
                RoomList           = "\All Contoso-Rooms"
                Ensure             = 'Present'
                GlobalAdminAccount = $GlobalAdminAccount
            }

            Mock -CommandName Get-AddressBookPolicy -MockWith {
                return @{
                    Name               = "Contoso ABP"
                    AddressLists       = "\All Contoso"
                    GlobalAddressList  = "\All Contoso"
                    OfflineAddressBook = "\Contoso-All-OAB"
                    RoomList           = "\All Fabrikam-Rooms"
                }
            }

            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should Be $false
            }

            Mock -CommandName Set-AddressBookPolicy -MockWith {
                return @{
                    Name               = "Contoso ABP"
                    AddressLists       = "\All Contoso"
                    GlobalAddressList  = "\All Contoso"
                    OfflineAddressBook = "\Contoso-All-OAB"
                    RoomList           = "\All Contoso-Rooms"
                    Ensure             = 'Present'
                    GlobalAdminAccount = $GlobalAdminAccount
                }
            }

            It "Should call the Set method" {
                Set-TargetResource @testParams
            }
        }

        Context -Name "ReverseDSC Tests" -Fixture {
            $testParams = @{
                GlobalAdminAccount = $GlobalAdminAccount
            }

            $AddressBookPolicy = @{
                Name               = "Contoso ABP"
                AddressLists       = "\All Contoso"
                GlobalAddressList  = "\All Contoso"
                OfflineAddressBook = "\Contoso-All-OAB"
                RoomList           = "\All Contoso-Rooms"
            }

            It "Should Reverse Engineer resource from the Export method when single" {
                Mock -CommandName Get-AddressBookPolicy -MockWith {
                    return $AddressBookPolicy
                }

                $exported = Export-TargetResource @testParams
                ([regex]::Matches($exported, " EXOAddressBookPolicy " )).Count | Should Be 1
                $exported.Contains("Contoso ABP") | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:DscHelper.CleanupScript -NoNewScope


$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests", "")
. "$pwd\$sut"

Describe "when converting yaml it should have properties and values" {

    $employeeRecord1 = @"
---
# An employee record
name: Example Developer
job: Developer
skill: Elite
"@

        $employeeRecord2 = @"
---
# An employee record
{name: Example Developer, job: Developer, skill: Elite}
"@ 
        $employeeRecord3 = @"
---
# An employee record
name: Example Developer
job: Developer
skill: Elite
employed: True
foods:
    - Apple
    - Orange
    - Strawberry
    - Mango
languages:
    ruby: Elite
    python: Elite
    dotnet: Lame
"@ 

    Context "Employee Record 1 Data" {

        $result = $employeeRecord1 | ConvertFrom-Yaml

        It "should these names and values" {
            $result.name | Should Be 'Example Developer' 
            $result.job | Should Be Developer 
            $result.skill | Should Be Elite
        }
    }

    Context "Employee Record 2 Data" {

        $result = $employeeRecord2 | ConvertFrom-Yaml

        It "should these names and values" {
            $result.name | Should Be 'Example Developer' 
            $result.job | Should Be Developer 
            $result.skill | Should Be Elite
        }
    }

    Context "Employee Record 3 Data" {

        $result = $employeeRecord3 | ConvertFrom-Yaml

        It "should have a name" {
            $result.name | Should Be "Example Developer"
        }

        It "should have a job" {
            $result.job | Should Be "Developer"
        }

        It "should have skill" {
            $result.skill | Should Be "Elite"
        }

        It "should have 4 foods" {
            $result.foods.count | Should Be 4
        }

        It "should be employeed" {
            $result.employed | Should Be 'true'
        }

        It "should have three languages" {
            ($result.languages|gm -MemberType NoteProperty).count | Should Be 3
        }

    }
}

Describe "a sequence" {
    $s = @"
foods:
    - Apple
    - Orange
    - Strawberry
    - Mango
"@

    $result = $s | ConvertFrom-Yaml
    
    Context "This sequence" {
        It "should be an array" {
            $result.foods.gettype().basetype.name | Should Be Array
        }

        It "should have 4 items" {
            $result.foods.count | Should Be 4
        }

        It "should have an Apple" {
            $result.foods[0] | Should Be Apple
        }

        It "should have an Orange" {
            $result.foods[1] | Should Be Orange
        }

        It "should have an Strawberry" {
            $result.foods[2] | Should Be Strawberry
        }

        It "should have an Mango" {
            $result.foods[3] | Should Be Mango
        }
    }
}

Describe "a map" {
    $s = @"
languages:
    ruby: Elite
    python: Elite
    dotnet: Lame
"@

    $result = $s | ConvertFrom-Yaml
    
    Context "This map" {
        It "should be an object" {
            $result.languages.gettype().basetype.name | Should Be Object
        }

        It "should have a property ruby with a value elite" {
            $result.languages.ruby | Should Be Elite
        }

        It "should have a property python with a value elite" {
            $result.languages.python | Should Be Elite
        }
    }
}

Describe "when converting yaml sequences|maps" {

$obj=@"
men: [John Smith, Bill Jones]
women:
  - Mary Smith
  - Susan Williams
"@ | ConvertFrom-Yaml
    
    Context "The sequence" {   
        It "should have two men" {
            $obj.men.count | should be 2
        }

        It "should have two women" {
            $obj.women.count | should be 2
        }
    }

    Context "The food sequence" {
$obj=@"
foods:
    - Apple
    - Orange
    - Strawberry
    - Mango
"@ | ConvertFrom-Yaml

        It "should have food type of object" {
            $obj.foods.gettype().name | should be "Object[]"
        }

        It "should have 4 foods" {
            $obj.foods.count | should be 4
        }

        It "should have each of these foods" {
            $obj.foods -eq 'apple'| should be 'apple'
            $obj.foods -eq 'orange'| should be 'orange'
            $obj.foods -eq 'Strawberry'| should be 'Strawberry'
            $obj.foods -eq 'Mango'| should be 'Mango'
        }

    }

    Context "the map" {
    $obj=@"
product:
    - sku         : BL4438H
      quantity    : 1
      description : Super Hoop
      price       : 2392.00
    - sku         : BL394D
      quantity    : 4
      description : Basketball
"@ | ConvertFrom-Yaml
        
        It "should have two products" {
            $obj.product.count | should be 2
        }

        It "should have 4 properties in the first product" {
            ($obj.product[0]|Get-Member -MemberType Properties).count | should be 4
        }

        It "should have these properties in the first product" {
            $names=($obj.product[0]|Get-Member -MemberType Properties).name
            $names -eq 'sku' | should be 'sku'
            $names -eq 'quantity' | should be 'quantity'
            $names -eq 'description' | should be 'description'
            $names -eq 'price' | should be 'price'
        }

        It "should have these values in the first product" {
            $obj.product[0].sku | should be 'BL4438H'
            $obj.product[0].quantity | should be '1'
            $obj.product[0].description | should be 'Super Hoop'
            $obj.product[0].price | should be '2392.00'
        }
        
        It "should have 3 properties in the second product" {
            ($obj.product[1]|Get-Member -MemberType Properties).count | should be 3
        }

        It "should have these properties in the second product" {
            $names=($obj.product[1]|Get-Member -MemberType Properties).name
            $names -eq 'sku' | should be 'sku'
            $names -eq 'quantity' | should be 'quantity'
            $names -eq 'description' | should be 'description'

            # should not be there
            $names -eq 'price' | should be $null
        }

        It "should have these values in the second product" {
            $obj.product[1].sku | should be 'BL394D'
            $obj.product[1].quantity | should be '4'
            $obj.product[1].description | should be 'Basketball'            
        }
    }
}

    Describe "yaml repeated nodes" {
$obj=@"
--- 
invoice: 34843
date   : 2001-01-23
bill-to: &id001
    given  : Chris
    family : Dumars
    address:
        lines: |
            458 Walkman Dr.
            Suite #292
        city    : Royal Oak
        state   : MI
        postal  : 48046
ship-to: *id001
product:
    - sku         : BL394D
      quantity    : 4
      description : Basketball
      price       : 450.00
    - sku         : BL4438H
      quantity    : 1
      description : Super Hoop
      price       : 2392.00
tax  : 251.42
total: 4443.52
comments: >
    Late afternoon is best.
    Backup contact is Nancy
    Billsmer @ 338-4338.
"@ | ConvertFrom-Yaml

    Context "the repeat" {
        It "bill-to address should be the same in ship-to" {
            $obj.'bill-to'.address.lines | should be $obj.'ship-to'.address.lines        
        }
    }
}
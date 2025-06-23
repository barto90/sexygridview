function Out-SexyGridView {
    <#
    .SYNOPSIS
    Displays objects in a modern, interactive grid view with advanced navigation and search capabilities.

    .DESCRIPTION
    Out-SexyGridView is an enhanced replacement for PowerShell's built-in Out-GridView cmdlet. 
    It provides a modern WPF-based interface with advanced features including:
    
    - Real-time search functionality across all object properties
    - Recursive navigation through complex nested objects via clickable buttons
    - Smart detection and handling of simple vs complex properties
    - Support for arrays with automatic Index/Value column creation
    - Dark and Light theme support
    - Data summary panel with object type statistics
    - Two view modes: Default (optimized columns) and Full (all properties)
    
    The cmdlet automatically detects complex properties (objects, hashtables, arrays) and displays 
    them as "View Object" buttons that open new grid windows for drilling down into nested data structures.

    .PARAMETER InputObject
    Specifies the objects to display in the grid view. This parameter accepts input from the pipeline.
    Supports any .NET object, PowerShell custom objects, hashtables, and arrays.

    .PARAMETER Title
    Specifies the title for the grid view window. By default, includes the command invocation unless RemoveTitleSuffix is used.
    Default value: "Sexy Grid View"

    .PARAMETER RemoveTitleSuffix
    When specified, removes the command invocation from the window title, showing only the base title.

    .PARAMETER ViewMode
    Specifies how properties are displayed in the grid:
    - Default: Shows optimized columns based on PowerShell's default property selection
    - Full: Shows all available properties as columns
    Default value: "Default"

    .PARAMETER Theme
    Specifies the visual theme for the grid view:
    - Dark: Dark background with light text (optimized for low-light environments)
    - Light: Light background with dark text (traditional Windows appearance)
    Default value: "Dark"

    .INPUTS
    System.Object
    You can pipe any objects to Out-SexyGridView.

    .OUTPUTS
    None
    Out-SexyGridView does not generate any output. It displays objects in an interactive window.

    .EXAMPLE
    Get-Process | Out-SexyGridView
    
    Displays all running processes in the sexy grid view with default settings.

    .EXAMPLE
    Get-Service | Out-SexyGridView -Title "System Services" -Theme Light
    
    Displays all services with a custom title using the light theme.

    .EXAMPLE
    Get-ChildItem C:\Windows\System32\*.exe | Out-SexyGridView -ViewMode Full
    
    Shows all executable files in System32 with all available properties displayed as columns.

    .EXAMPLE
    $servers = @(
        [PSCustomObject]@{
            Name = "Server01"
            Config = [PSCustomObject]@{
                CPU = "Intel Xeon"
                Network = @{IP = "192.168.1.10"; Ports = @(80, 443)}
            }
        }
    )
    $servers | Out-SexyGridView -Title "Server Infrastructure"
    
    Demonstrates complex object navigation. The Config property will show as a "View Object" button 
    that opens a new window with the nested configuration details.

    .EXAMPLE
    @("Production", "Staging", "Development") | Out-SexyGridView -Title "Environments"
    
    Shows how arrays of simple types are handled with automatic Index/Value columns.

    .EXAMPLE
    Get-WmiObject Win32_ComputerSystem | Out-SexyGridView -RemoveTitleSuffix -Theme Light
    
    Displays computer system information with a clean title (no command suffix) in light theme.

    .NOTES
    Requirements:
    - PowerShell 5.1 or later
    - .NET Framework 4.7.2 or later
    - Windows with WPF support

    The cmdlet uses WPF (Windows Presentation Foundation) for the user interface and requires 
    the PresentationFramework, PresentationCore, and WindowsBase assemblies.

    For optimal performance with large datasets, consider filtering data before piping to Out-SexyGridView.

    .LINK
    Out-GridView
    
    .LINK
    https://github.com/barto90/sexygridview
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $false)]
        [string]$Title = 'Sexy Grid View',

        [Parameter(Mandatory = $false)]
        [switch]$RemoveTitleSuffix,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Default', 'Full')]
        [string]$ViewMode = 'Default',

        [Parameter(Mandatory = $false)]
        [string]$Theme = 'Dark'
    )

    begin {
        $allObjects = @()

        if(-not $RemoveTitleSuffix) {
            $commandInvocation = $MyInvocation.Line
            $Title = "$($Title) - $($commandInvocation)"
        }
    }

    process {   
        if ($null -ne $InputObject) {
            $allObjects += $InputObject
        }    
    }

    end {
        if ($allObjects.Count -gt 0) {
            Out-SexyGridViewForm -Title $Title -AllObjects $allObjects -ViewMode $ViewMode -Theme $Theme
        } else {
            Write-Warning "No objects to display"
            return;
        }
    }
}

function Get-Theme {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Dark', 'Light')] 
        [string]$Theme = 'Dark'
    )

    $themes = @{
        Dark = @{
            Window = @{ Width = 1000; Height = 600 }
            DataGrid = @{ Background = 'White'; Foreground = 'Black'; BorderBrush = '#464647' }
            Background = '#2D2D30'
            Foreground = '#F1F1F1'
            HeaderBackground = '#3F3F46'
            SelectionBackground = '#007ACC'
            BorderBrush = '#464647'
            GridLinesBrush = '#404040'
            TextForeground = '#F1F1F1'
        }
        Light = @{
            Window = @{ Width = 1000; Height = 600 }
            DataGrid = @{ Background = 'White'; Foreground = 'Black'; BorderBrush = '#464647' }
            Background = '#FFFFFF'
            Foreground = '#1E1E1E'
            HeaderBackground = '#F3F3F3'
            SelectionBackground = '#0078D4'
            BorderBrush = '#D1D1D1'
            GridLinesBrush = '#E0E0E0'
            TextForeground = '#1E1E1E'
        }
    }
    return $themes[$Theme]
}

function Out-SexyGridViewForm {
    [CmdletBinding()]
    param (        
        [Parameter(Mandatory = $true)]
        [object]$AllObjects,

        [Parameter(Mandatory = $false)]
        [string]$Title,
        
        [Parameter(Mandatory = $false)]
        [string]$ViewMode,

        [Parameter(Mandatory = $false)]
        [string]$Theme
    )

    $requiredAssemblies = @('PresentationFramework', 'PresentationCore', 'WindowsBase')
    foreach ($assembly in $requiredAssemblies) {
        Add-Type -AssemblyName $assembly -ErrorAction Stop 
    }

    $themeConfig = Get-Theme -Theme $Theme
    if($null -eq $themeConfig) {
        Write-Error "Failed to get theme"
        return
    }

    $window = New-MainWindow -Title $Title -Theme $themeConfig
    $mainGrid = New-MainGridLayout
    $dataGrid = New-DataGrid -Theme $themeConfig -AllObjects $AllObjects -ViewMode $ViewMode
    $searchBar = New-SearchBar -Theme $themeConfig -DataGrid $dataGrid
    $dataSummary = New-DataSummaryPanel -Theme $themeConfig -DataGrid $dataGrid
     
    [System.Windows.Controls.Grid]::SetRow($searchBar, 0)
    [System.Windows.Controls.Grid]::SetRow($dataSummary, 1)
    [System.Windows.Controls.Grid]::SetRow($dataGrid, 2)

    $mainGrid.Children.Add($searchBar) | Out-Null
    $mainGrid.Children.Add($dataSummary) | Out-Null
    $mainGrid.Children.Add($dataGrid) | Out-Null

    $window.Content = $mainGrid

    $window.ShowDialog() | Out-Null
    $window.Activate() | Out-Null        
}

function New-MainWindow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [hashtable]$Theme
    )

    $window = New-Object System.Windows.Window
    $window.Title = $Title
    $window.Width = $Theme.Window.Width
    $window.Height = $Theme.Window.Height
    $window.WindowStartupLocation = 'CenterScreen'
    $window.Background = $Theme.Background

    return $window;        
}

function New-MainGridLayout {
    $grid = New-Object System.Windows.Controls.Grid

    $searchRow = New-Object System.Windows.Controls.RowDefinition
    $searchRow.Height = 'Auto'
    $grid.RowDefinitions.Add($searchRow) | Out-Null

    $summaryRow = New-Object System.Windows.Controls.RowDefinition
    $summaryRow.Height = 'Auto'
    $grid.RowDefinitions.Add($summaryRow) | Out-Null

    $dataGridRow = New-Object System.Windows.Controls.RowDefinition
    $dataGridRow.Height = '*'
    $grid.RowDefinitions.Add($dataGridRow) | Out-Null

    return $grid        
}

function New-SearchBar {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Theme,

        [Parameter(Mandatory = $true)]
        [System.Windows.Controls.DataGrid]$DataGrid
    )

    $mainStackPanel = New-Object System.Windows.Controls.StackPanel
    $mainStackPanel.Margin = '5'

    $searchBox = New-Object System.Windows.Controls.TextBox
    $searchBox.HorizontalAlignment = 'Stretch'
    $searchBox.Margin = '0,0,0,5'
    $searchBox.Background = $Theme.Background
    $searchBox.Foreground = $Theme.TextForeground
    $searchBox.BorderBrush = $Theme.BorderBrush
    $searchBox.Padding = '5,2'
    $searchBox.FontSize = 12
    $searchBox.Text = 'Search...'
    $searchBox.Foreground = [System.Windows.Media.Brushes]::LightGray 

    $resultsText = New-Object System.Windows.Controls.TextBlock
    $resultsText.Margin = '0,5,0,0'
    $resultsText.Foreground = $Theme.Foreground
    $resultsText.FontSize = 11
    $resultsText.Text = "Total Items: $($DataGrid.Items.Count)"

    $script:resultsTextBlock = $resultsText

    $searchBox.Add_GotFocus({
        if ($this.Text -eq 'Search...') {
            $this.Text = ''
            $this.Foreground = [System.Windows.Media.Brushes]::LightGray 
        }
    })

    $searchBox.Add_LostFocus({
        if ($this.Text -eq '') {
            $this.Text = 'Search...'
            $this.Foreground = [System.Windows.Media.Brushes]::LightGray 
        }
    })

    $searchBox.Add_TextChanged({
        param($sender, $e)
        
        $searchText = $sender.Text.ToLower()
        if ($searchText -eq "search...") { $searchText = '' }
        
        $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($DataGrid.ItemsSource)
        if ($view) {
            $view.Filter = {
                param($item)
                if ([string]::IsNullOrEmpty($searchText)) { return $true }                    
                if ($item -is [hashtable]) {
                    foreach ($value in $item.Values) {
                        if ($value -ne $null -and $value.ToString().ToLower().Contains($searchText)) {
                            return $true
                        }
                    }
                    return $false
                } else {
                    $properties = $item.PSObject.Properties
                    foreach ($prop in $properties) {
                        if ($prop.Value -ne $null -and $prop.Value.ToString().ToLower().Contains($searchText)) {
                            return $true
                        }
                    }
                    return $false
                }
            }

            $totalItems = $DataGrid.Items.Count
            $filteredItems = ($view | Where-Object { $_ -ne $null }).Count
            if ([string]::IsNullOrEmpty($searchText)) {
                $script:resultsTextBlock.Text = "Total Items: $totalItems"
            } else {
                $script:resultsTextBlock.Text = "Showing $filteredItems of $totalItems items"
            }

            if ($script:summaryTextBlock) {
                $typeCounts = @{}
                $totalCount = 0
                
                foreach ($item in $DataGrid.ItemsSource) {
                    $typeName = $item.GetType().Name
                    $totalCount++
                    if ($typeCounts.ContainsKey($typeName)) {
                        $typeCounts[$typeName]++
                    } else {
                        $typeCounts[$typeName] = 1
                    }
                }
                
                $summary = "Total Objects: $totalCount`n`n"
                $sortedTypes = $typeCounts.GetEnumerator() | Sort-Object Value -Descending
                foreach ($type in $sortedTypes) {
                    $percentage = [math]::Round(($type.Value / $totalCount) * 100, 1)
                    $summary += "$($type.Key.PadRight(20)) : $($type.Value.ToString().PadLeft(6)) ($percentage%)`n"
                }
                $script:summaryTextBlock.Text = $summary
            }
        }
    })

    $mainStackPanel.Children.Add($searchBox) | Out-Null
    $mainStackPanel.Children.Add($resultsText) | Out-Null

    return $mainStackPanel
}

function Get-CollectionProperties {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$AllObjects
    )

    $allProperties = @()
    $firstObject = $AllObjects[0]
    if ($firstObject -is [hashtable]) {           
        $allProperties = $firstObject.Keys
    } else {
        foreach ($object in $AllObjects) {            
            $tableOutput = $object | Format-Table | Out-String
            $lines = $tableOutput -split "`n"
            $headerLine = $null
            for ($i = 0; $i -lt ($lines.Length - 1); $i++) {
                $currentLine = $lines[$i].Trim()
                $nextLine = $lines[$i + 1].Trim()
                if ($currentLine -ne '' -and $nextLine -match '^[-\s]+$') {
                    $headerLine = $currentLine
                    break
                }
            }

            if ($headerLine) {
                $defaultProperties = $headerLine -split '\s+' | Where-Object { $_ -ne '' }
                foreach ($property in $defaultProperties) {
                    if(-not $allProperties.Contains($property)) {
                        $allProperties += $property
                    }
                }
            }
        }
    }
    return $allProperties
}

function New-DataGrid {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Theme,

        [Parameter(Mandatory = $true)]
        [object]$AllObjects,
        
        [Parameter(Mandatory = $false)]       
        [string]$ViewMode
    )

    $dataGrid = New-Object System.Windows.Controls.DataGrid
    $dataGrid.AutoGenerateColumns = $false

    if($ViewMode -eq 'Full') {
        $dataGrid.AutoGenerateColumns = $true
        $dataGrid.ItemsSource = $AllObjects          
    } else {
        $firstItem = $AllObjects[0]
        $isSimpleArray = $false
        if ($AllObjects.GetType().IsArray -and $firstItem -ne $null) {
            $simpleTypes = @('String', 'Int32', 'Int64', 'Double', 'Boolean', 'DateTime', 'Decimal', 'Single', 'Byte')
            if ($firstItem.GetType().Name -in $simpleTypes) {
                $isSimpleArray = $true
            }
        }
        
        if ($isSimpleArray) {
            $convertedObjects = @()
            for ($i = 0; $i -lt $AllObjects.Count; $i++) {
                $convertedObjects += [PSCustomObject]@{
                    Index = $i
                    Value = $AllObjects[$i]
                }
            }
            $dataGrid.ItemsSource = $convertedObjects
            
            $indexColumn = New-Object System.Windows.Controls.DataGridTextColumn
            $indexColumn.Header = "Index"
            $indexColumn.Binding = New-Object System.Windows.Data.Binding "Index"
            $dataGrid.Columns.Add($indexColumn) | Out-Null
            
            $valueColumn = New-Object System.Windows.Controls.DataGridTextColumn
            $valueColumn.Header = "Value"
            $valueColumn.Binding = New-Object System.Windows.Data.Binding "Value"
            $dataGrid.Columns.Add($valueColumn) | Out-Null
            
        } else {                   
            $collectionProperties = Get-CollectionProperties -AllObjects $AllObjects

            foreach ($propertyName in $collectionProperties) {               
                $sampleCount = 10
                $isComplexProperty = $false

                for ($i = 0; $i -lt $sampleCount; $i++) {
                    $sampleValue = $AllObjects[$i].$propertyName
                    if ($null -ne $sampleValue) {
                        $valueType = $sampleValue.GetType()
                        $simpleTypes = @('String', 'Int32', 'Int64', 'Double', 'Boolean', 'DateTime', 'Decimal', 'Single', 'Byte')
                        if ($valueType.Name -notin $simpleTypes -and 
                            ($sampleValue -is [PSObject] -or $sampleValue -is [Hashtable] -or 
                             $valueType.IsArray -or $valueType.IsClass -and $valueType.Name -ne 'String')) 
                        {
                            $isComplexProperty = $true
                            break
                        }
                    }
                }

                if($isComplexProperty) {
                    $templateColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
                    $templateColumn.Header = $propertyName
                    $templateColumn.Width = 120

                    $dataTemplate = New-Object System.Windows.DataTemplate
                    $buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])

                    $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "View Object")
                    $buttonFactory.SetValue([System.Windows.Controls.Button]::BackgroundProperty, [System.Windows.Media.Brushes]::Transparent)               
                    $buttonFactory.SetValue([System.Windows.Controls.Button]::ForegroundProperty, [System.Windows.Media.Brushes]::Blue)
                    $buttonFactory.SetValue([System.Windows.Controls.Button]::CursorProperty, [System.Windows.Input.Cursors]::Hand)
                    

                    $binding = New-Object System.Windows.Data.Binding $propertyName
                    $buttonFactory.SetBinding([System.Windows.Controls.Button]::TagProperty, $binding)
      

                    $clickHandler = [System.Windows.RoutedEventHandler] {
                        param($sender, $e)
                        $propertyValue = $sender.Tag
                        if ($null -ne $propertyValue) {
                            $propertyValue | Out-SexyGridView -Title "Object Details: $propertyName" -Theme $Theme
                        }
                    }
                    $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent, $clickHandler)
                    
                    $dataTemplate.VisualTree = $buttonFactory
                    $templateColumn.CellTemplate = $dataTemplate
                    $dataGrid.Columns.Add($templateColumn) | Out-Null

                } else {
                    $column = New-Object System.Windows.Controls.DataGridTextColumn
                    $column.Header = $propertyName
                    $column.Binding = New-Object System.Windows.Data.Binding $propertyName
                    $dataGrid.Columns.Add($column) | Out-Null
                }
            }
            $dataGrid.ItemsSource = $AllObjects
        }
    }
        
    $dataGrid.Background = $Theme.DataGrid.Background
    $dataGrid.Foreground = $Theme.DataGrid.Foreground
    $dataGrid.BorderBrush = $Theme.BorderBrush
    $dataGrid.BorderThickness = '1'
    
    $dataGrid.GridLinesVisibility = 'All'
    $dataGrid.HorizontalGridLinesBrush = '#E0E0E0'
    $dataGrid.VerticalGridLinesBrush = '#E0E0E0'
    
    $dataGrid.ColumnHeaderHeight = 25
    $dataGrid.HeadersVisibility = 'Column'
    
    $dataGrid.RowHeight = 22
    $dataGrid.AlternatingRowBackground = '#F8F8F8'
    $dataGrid.RowBackground = 'White'
    
    $dataGrid.SelectionMode = 'Extended'
    $dataGrid.SelectionUnit = 'FullRow'
    
    $dataGrid.IsReadOnly = $true
    $dataGrid.CanUserAddRows = $false
    $dataGrid.CanUserDeleteRows = $false
    $dataGrid.CanUserReorderColumns = $true
    $dataGrid.CanUserResizeColumns = $true
    $dataGrid.CanUserResizeRows = $false
    $dataGrid.CanUserSortColumns = $true
    
    $dataGrid.HorizontalAlignment = 'Stretch'
    $dataGrid.VerticalAlignment = 'Stretch'
    $dataGrid.Margin = '0'
    
    $dataGrid.HorizontalScrollBarVisibility = 'Auto'
    $dataGrid.VerticalScrollBarVisibility = 'Auto'
    
    return $dataGrid     
}

function New-DataSummaryPanel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Theme,

        [Parameter(Mandatory = $true)]
        [System.Windows.Controls.DataGrid]$DataGrid
    )

    $expander = New-Object System.Windows.Controls.Expander
    $expander.Header = "Data Summary"
    $expander.Foreground = $Theme.Foreground
    $expander.BorderBrush = $Theme.BorderBrush
    $expander.Margin = '0,5,0,0'
    $expander.IsExpanded = $false

    $summaryText = New-Object System.Windows.Controls.TextBlock
    $summaryText.Margin = '10,5,5,5'
    $summaryText.Foreground = $Theme.Foreground
    $summaryText.TextWrapping = 'Wrap'
    $summaryText.FontFamily = 'Consolas, Courier New, monospace'
    $summaryText.FontSize = 11

    $typeCounts = @{}
    $totalCount = 0
    
    foreach ($item in $DataGrid.ItemsSource) {
        $typeName = $item.GetType().Name
        $totalCount++
        if ($typeCounts.ContainsKey($typeName)) {
            $typeCounts[$typeName]++
        } else {
            $typeCounts[$typeName] = 1
        }
    }
    
    $summary = "Total Objects: $totalCount`n`n"
    $sortedTypes = $typeCounts.GetEnumerator() | Sort-Object Value -Descending
    foreach ($type in $sortedTypes) {
        $percentage = [math]::Round(($type.Value / $totalCount) * 100, 1)
        $summary += "$($type.Key.PadRight(20)) : $($type.Value.ToString().PadLeft(6)) ($percentage%)`n"
    }
    $summaryText.Text = $summary

    $expander.Content = $summaryText

    $script:summaryTextBlock = $summaryText

    return $expander
}
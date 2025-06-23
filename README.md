# Out-SexyGridView

A modern, interactive PowerShell grid viewer with advanced object navigation and search capabilities. Think `Out-GridView` but with superpowers! 🚀

## ✨ Features

- **🎨 Modern UI**: Clean, responsive interface with Dark/Light theme support
- **🔍 Real-time Search**: Instantly filter data across all properties
- **📊 Object Navigation**: Click through complex nested objects recursively
- **📈 Data Summary**: Expandable panel showing object type statistics
- **🗂️ Smart Column Detection**: Automatically handles simple and complex properties
- **⚡ Array Support**: Properly displays arrays of simple types with Index/Value columns
- **🎯 Interactive Buttons**: Clickable "View Object" buttons for nested data exploration
- **🔧 Flexible Modes**: Default view (optimized columns) or Full view (all properties)

## 📦 Installation

1. **Clone or Download** this repository
2. **Import the module**:
   ```powershell
   Import-Module .\Out-SexyGridview.psm1
   ```

## 🚀 Quick Start

```powershell
# Basic usage
Get-Process | Out-SexyGridView

# With custom title
Get-Service | Out-SexyGridView -Title "System Services"

# Dark theme (default)
Get-ChildItem | Out-SexyGridView -Theme Dark

# Light theme
Get-WmiObject Win32_ComputerSystem | Out-SexyGridView -Theme Light

# Full property view
Get-Module | Out-SexyGridView -ViewMode Full
```

## 📝 Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `InputObject` | Object | *Required* | Objects to display in the grid |
| `Title` | String | "Sexy Grid View" | Window title |
| `RemoveTitleSuffix` | Switch | `$false` | Remove the command invocation from title |
| `ViewMode` | String | "Default" | `Default` (optimized) or `Full` (all properties) |
| `Theme` | String | "Dark" | `Dark` or `Light` theme |

## 🎯 Usage Examples

### Basic Objects
```powershell
# Display running processes
Get-Process | Out-SexyGridView -Title "Running Processes"

# Show system services with light theme
Get-Service | Out-SexyGridView -Theme Light -Title "System Services"
```

### Complex Nested Objects
```powershell
# Create complex test data
$servers = @(
    [PSCustomObject]@{
        Name = "Server01"
        Status = "Online"
        Config = [PSCustomObject]@{
            CPU = "Intel Xeon"
            RAM = "32GB"
            Network = [PSCustomObject]@{
                IP = "192.168.1.10"
                Ports = @(80, 443, 3389)
                Settings = @{
                    DHCP = $true
                    DNS = @("8.8.8.8", "1.1.1.1")
                }
            }
        }
    }
)

# Display with navigation capabilities
$servers | Out-SexyGridView -Title "Server Infrastructure"
```

### Array Data
```powershell
# Arrays of simple types get Index/Value columns
@("Production", "Staging", "Development") | Out-SexyGridView -Title "Environments"

# Arrays of numbers
@(100, 200, 350, 450) | Out-SexyGridView -Title "Response Times (ms)"
```

### Registry and WMI Objects
```powershell
# Windows features
Get-WindowsFeature | Out-SexyGridView -Title "Windows Features"

# WMI computer information
Get-WmiObject Win32_ComputerSystem | Out-SexyGridView -ViewMode Full

# Registry keys (if you have access)
Get-ChildItem "HKLM:\SOFTWARE\Microsoft" | Out-SexyGridView
```

## 🔍 Interactive Features

### Search Functionality
- **Real-time filtering**: Type in the search box to instantly filter rows
- **Multi-property search**: Searches across all visible columns
- **Case-insensitive**: Works regardless of text case
- **Live counter**: Shows "Showing X of Y items" during filtering

### Object Navigation
- **Complex Properties**: Automatically detected and shown as "View Object" buttons
- **Recursive Drilling**: Click buttons to open new windows with nested object data
- **Array Handling**: Simple arrays converted to Index/Value format
- **Hashtable Support**: Properly displays PowerShell hashtables

### Data Summary Panel
- **Type Statistics**: Shows count and percentage of each object type
- **Expandable**: Click to show/hide the summary information
- **Live Updates**: Refreshes when search filters change

## 🎨 Themes

### Dark Theme (Default)
- Dark background with light text
- Blue selection highlighting
- Optimized for low-light environments

### Light Theme
- Light background with dark text
- Blue selection highlighting  
- Traditional Windows appearance

```powershell
# Switch themes
$data | Out-SexyGridView -Theme Dark   # Default
$data | Out-SexyGridView -Theme Light  # Light theme
```

## 🔧 View Modes

### Default Mode
- Shows optimized columns based on PowerShell's default display
- Cleaner, more focused view
- Recommended for most scenarios

### Full Mode
- Shows ALL object properties as columns
- Comprehensive but potentially overwhelming
- Useful for object exploration

```powershell
# Compare view modes
Get-Process | Out-SexyGridView -ViewMode Default  # Optimized columns
Get-Process | Out-SexyGridView -ViewMode Full     # All properties
```

## 🏗️ Architecture

The module consists of several key functions:

- **`Out-SexyGridView`**: Main entry point and pipeline handler
- **`Get-Theme`**: Theme configuration management
- **`Out-SexyGridViewForm`**: WPF window creation and orchestration
- **`New-MainWindow`**: Main window setup
- **`New-MainGridLayout`**: Grid layout configuration
- **`New-SearchBar`**: Search functionality with live filtering
- **`New-DataGrid`**: Core grid with complex object handling
- **`New-DataSummaryPanel`**: Statistics and summary display
- **`Get-CollectionProperties`**: Intelligent property detection

## 🎯 Advanced Examples

### Pipeline Processing
```powershell
# Process pipeline data
Get-ChildItem C:\Windows\System32\*.exe | 
    Where-Object Length -gt 1MB |
    Out-SexyGridView -Title "Large Executables"
```

### Custom Objects
```powershell
# Create and display custom objects
1..5 | ForEach-Object {
    [PSCustomObject]@{
        ID = $_
        Name = "Item$_"
        Data = [PSCustomObject]@{
            Type = "Custom"
            Values = @(($_ * 10)..($_ * 10 + 5))
            Config = @{
                Enabled = ($_ % 2 -eq 0)
                Priority = ("High", "Medium", "Low")[$_ % 3]
            }
        }
    }
} | Out-SexyGridView -Title "Custom Object Demo"
```

### JSON Data
```powershell
# Parse and display JSON
$json = @'
[
  {"name": "Alice", "age": 30, "city": "New York"},
  {"name": "Bob", "age": 25, "city": "Los Angeles"}
]
'@

$json | ConvertFrom-Json | Out-SexyGridView -Title "JSON Data"
```

## 🔍 Tips & Tricks

1. **Search Performance**: Search is case-insensitive and searches all visible properties
2. **Navigation**: Use Ctrl+Click on "View Object" buttons to open in new windows
3. **Sorting**: Click column headers to sort data (standard DataGrid behavior)
4. **Resizing**: Drag column borders to resize, or double-click to auto-fit
5. **Selection**: Use Ctrl/Shift for multi-row selection
6. **Copy**: Selected rows can be copied to clipboard (Ctrl+C)

## 🐛 Troubleshooting

### Common Issues
- **Missing WPF Assemblies**: Ensure you're running PowerShell 5.1+ or PowerShell 7+ with Windows PowerShell compatibility
- **Complex Objects Not Showing**: Check that objects have accessible properties
- **Search Not Working**: Verify objects have string representations of their properties

### Performance
- **Large Datasets**: Consider filtering data before piping to Out-SexyGridView
- **Deep Nesting**: Very deep object hierarchies may impact performance
- **Memory Usage**: Each recursive window maintains its own data copy

## 🤝 Contributing

Feel free to contribute improvements, bug fixes, or new features:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is provided as-is for educational and productivity purposes. Feel free to modify and distribute according to your needs.

## 🙏 Acknowledgments

Inspired by PowerShell's built-in `Out-GridView` cmdlet, but enhanced with modern UI principles and advanced object navigation capabilities.

---

**Happy data exploring!** 🎉

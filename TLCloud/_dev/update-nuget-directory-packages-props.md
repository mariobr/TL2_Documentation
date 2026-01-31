# Updating NuGet Packages in a .NET Solution Using `Directory.Packages.props`

When using a centralized `Directory.Packages.props` file in a .NET solution (Central Package Management), all NuGet versions are managed in that single file instead of individual `.csproj` files.

---

## 🔧 Option 1: Manual Update

1. Open **`Directory.Packages.props`**.
2. Locate entries like this:

   ```xml
   <ItemGroup>
     <PackageVersion Include="Newtonsoft.Json" Version="13.0.1" />
     <PackageVersion Include="Serilog" Version="2.12.0" />
   </ItemGroup>
   ```

3. Check for the latest versions by running:

   ```bash
   dotnet tlcloud.sln list package --outdated
   ```

4. Update the version numbers manually in the file, then restore the solution:

   ```bash
   dotnet restore
   ```

---

## ⚙️ Option 2: Automated Update Using CLI Tool

You can automate this process using the [`dotnet-outdated`](https://github.com/dotnet-outdated/dotnet-outdated) tool.

1. Install the tool globally:

   ```bash
   dotnet tool install --global dotnet-outdated-tool
   ```

2. Run the update command:

   ```bash
   dotnet outdated --upgrade
   ```

   This will detect outdated packages and update the versions directly in `Directory.Packages.props`.

**Optional flags:**
- `--pre` → include prerelease versions  
- `--include-transitive` → include transitive dependencies

---

## 🧩 Option 3: Using Visual Studio

If you're using **Visual Studio 2022 (v17.3 or later)**:

1. Right-click the **solution** → **Manage NuGet Packages for Solution...**
2. Go to the **Updates** tab.
3. Select the packages and click **Update**.

Visual Studio will automatically update versions in `Directory.Packages.props` when Central Package Management is enabled.

---

## ✅ Best Practices

- Keep all version information **only** in `Directory.Packages.props`.
- Use `dotnet list package --outdated` regularly to check for updates.
- Commit the updated file to version control to ensure all team members use the same versions.

---

**Example:**

```bash
dotnet tool install --global dotnet-outdated-tool
dotnet outdated --upgrade
dotnet restore
```

All projects sharing `Directory.Packages.props` will now use the latest stable package versions.

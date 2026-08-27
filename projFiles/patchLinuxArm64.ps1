$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

function Patch-File($path, $marker, $edits) {
    if (-not (Test-Path $path)) {
        Write-Warning "Skipping (not found): $path"
        return
    }

    $crlf = $false
    $raw = Get-Content -Raw -Path $path
    if ($raw.Contains("`r`n")) { $crlf = $true }
    $content = $raw -replace "`r`n", "`n"

    if ($content.Contains($marker)) {
        Write-Host "Already patched: $path"
        return
    }

    $original = $content
    foreach ($edit in $edits) {
        $find = $edit.Find -replace "`r`n", "`n"
        $replace = $edit.Replace -replace "`r`n", "`n"
        if (-not $content.Contains($find)) {
            throw "Could not find expected text in $path (haxelib version mismatch? edit this script to match). Looking for:`n$find"
        }
        $content = $content.Replace($find, $replace)
    }

    if ($content -eq $original) {
        throw "No changes applied to $path even though marker was missing - inspect manually."
    }

    if ($crlf) { $content = $content -replace "`n", "`r`n" }

    Set-Content -Path $path -Value $content -NoNewline
    Write-Host "Patched: $path"
}

$linuxPlatformHx = Join-Path $repoRoot '.haxelib\lime\git\tools\platforms\LinuxPlatform.hx'

Patch-File $linuxPlatformHx 'isArm64' @(
    @{
        Find = @'
		var hxml = targetDirectory + "/haxe/" + buildType + ".hxml";

		System.mkdir(targetDirectory);

		for (dependency in project.dependencies)
		{
			if (StringTools.endsWith(dependency.path, ".so"))
			{
				copyIfNewer(dependency.path, applicationDirectory + "/" + Path.withoutDirectory(dependency.path));
			}
			else
			{
				copyIfNewer(Path.combine(dependency.path, "Linux" + (( System.hostArchitecture == ARMV7 || System.hostArchitecture == ARM64)?"Arm":"") + (is64 ? "64" : "") + "/" + dependency.name + ".so"), applicationDirectory + "/" + dependency.name + ".so");
			}
		}

		for (ndll in project.ndlls)
		{
			if (targetType == "hl")
			{
				ProjectHelper.copyLibrary(project, ndll, "Linux" + (is64 ? "64" : ""), "", ".hdll", applicationDirectory, project.debug, ".hdll");
			}
			else
			{
				ProjectHelper.copyLibrary(project, ndll, "Linux" + (( System.hostArchitecture == ARMV7 || System.hostArchitecture == ARM64)?"Arm":"") + (is64 ? "64" : ""), "", ".ndll", applicationDirectory, project.debug);
			}
		}
'@
        Replace = @'
		var hxml = targetDirectory + "/haxe/" + buildType + ".hxml";

		System.mkdir(targetDirectory);

		// requested via `-arm64`/`Architecture.ARM64`, e.g. cross-compiling to Linux ARM64 from a non-ARM64 host
		var targetArm64:Bool = project.architectures.indexOf(Architecture.ARM64) >= 0;
		var isArm64:Bool = System.hostArchitecture == ARM64 || targetArm64;

		for (dependency in project.dependencies)
		{
			if (StringTools.endsWith(dependency.path, ".so"))
			{
				copyIfNewer(dependency.path, applicationDirectory + "/" + Path.withoutDirectory(dependency.path));
			}
			else
			{
				copyIfNewer(Path.combine(dependency.path, "Linux" + (( System.hostArchitecture == ARMV7 || isArm64)?"Arm":"") + (is64 ? "64" : "") + "/" + dependency.name + ".so"), applicationDirectory + "/" + dependency.name + ".so");
			}
		}

		for (ndll in project.ndlls)
		{
			if (targetType == "hl")
			{
				ProjectHelper.copyLibrary(project, ndll, "Linux" + (is64 ? "64" : ""), "", ".hdll", applicationDirectory, project.debug, ".hdll");
			}
			else
			{
				ProjectHelper.copyLibrary(project, ndll, "Linux" + (( System.hostArchitecture == ARMV7 || isArm64)?"Arm":"") + (is64 ? "64" : ""), "", ".ndll", applicationDirectory, project.debug);
			}
		}
'@
    },
    @{
        Find = @'
			if (is64)
			{
				if (System.hostArchitecture == ARM64)
				{
					haxeArgs.push("-D");
					haxeArgs.push("HXCPP_ARM64");
					flags.push("-DHXCPP_ARM64");
				}
				else
				{
					haxeArgs.push("-D");
					haxeArgs.push("HXCPP_M64");
					flags.push("-DHXCPP_M64");
				}
			}
'@
        Replace = @'
			if (is64)
			{
				if (isArm64)
				{
					haxeArgs.push("-D");
					haxeArgs.push("HXCPP_ARM64");
					flags.push("-DHXCPP_ARM64");
				}
				else
				{
					haxeArgs.push("-D");
					haxeArgs.push("HXCPP_M64");
					flags.push("-DHXCPP_M64");
				}
			}
'@
    },
    @{
        Find = @'
				flags.push('-DHXCPP_XLINUX32_CXX=$hxcpp_xlinux32_cxx');
				flags.push('-DHXCPP_XLINUX32_STRIP=$hxcpp_xlinux32_strip');
				flags.push('-DHXCPP_XLINUX32_RANLIB=$hxcpp_xlinux32_ranlib');
				flags.push('-DHXCPP_XLINUX32_AR=$hxcpp_xlinux32_ar');
			}
'@
        Replace = @'
				flags.push('-DHXCPP_XLINUX32_CXX=$hxcpp_xlinux32_cxx');
				flags.push('-DHXCPP_XLINUX32_STRIP=$hxcpp_xlinux32_strip');
				flags.push('-DHXCPP_XLINUX32_RANLIB=$hxcpp_xlinux32_ranlib');
				flags.push('-DHXCPP_XLINUX32_AR=$hxcpp_xlinux32_ar');

				var hxcpp_xlinux_arm64_cxx = project.defines.get("HXCPP_XLINUX_ARM64_CXX");
				if (hxcpp_xlinux_arm64_cxx == null)
				{
					hxcpp_xlinux_arm64_cxx = "aarch64-linux-gnu-g++";
				}
				var hxcpp_xlinux_arm64_strip = project.defines.get("HXCPP_XLINUX_ARM64_STRIP");
				if (hxcpp_xlinux_arm64_strip == null)
				{
					hxcpp_xlinux_arm64_strip = "aarch64-linux-gnu-strip";
				}
				var hxcpp_xlinux_arm64_ranlib = project.defines.get("HXCPP_XLINUX_ARM64_RANLIB");
				if (hxcpp_xlinux_arm64_ranlib == null)
				{
					hxcpp_xlinux_arm64_ranlib = "aarch64-linux-gnu-ranlib";
				}
				var hxcpp_xlinux_arm64_ar = project.defines.get("HXCPP_XLINUX_ARM64_AR");
				if (hxcpp_xlinux_arm64_ar == null)
				{
					hxcpp_xlinux_arm64_ar = "aarch64-linux-gnu-ar";
				}
				flags.push('-DHXCPP_XLINUX_ARM64_CXX=$hxcpp_xlinux_arm64_cxx');
				flags.push('-DHXCPP_XLINUX_ARM64_STRIP=$hxcpp_xlinux_arm64_strip');
				flags.push('-DHXCPP_XLINUX_ARM64_RANLIB=$hxcpp_xlinux_arm64_ranlib');
				flags.push('-DHXCPP_XLINUX_ARM64_AR=$hxcpp_xlinux_arm64_ar');
			}
'@
    }
)

Patch-File $linuxPlatformHx 'cross-compiling `linux -arm64` from a non-ARM64' @(
    @{
        Find = @'
		var commands:Array<Array<String>> = [];

		if (targetFlags.exists('rpi') && System.hostArchitecture == ARM64 )
'@
        Replace = @'
		var commands:Array<Array<String>> = [];

		// cross-compiling `linux -arm64`` from a non-ARM64 (e.g. Windows) host. CXX/STRIP/AR/RANLIB
		// are deliberately *not* set here - `-Dxcompile` + `-DHXCPP_ARM64` are enough for
		// linux-toolchain.xml to resolve `${HXCPP_XLINUX_ARM64_CXX}` etc. itself, which in turn
		// come from hxcpp's own global .hxcpp_config.xml "vars" section (project.defines here is a
		// Lime-internal bootstrap project for rebuilding lime's own ndll, so it has no visibility
		// into project.hxp - unlike the `build()` cross-compile path above, which does).
		if (!targetFlags.exists('rpi') && System.hostArchitecture != ARM64 && (targetFlags.exists('arm64') || project.architectures.indexOf(Architecture.ARM64) >= 0))
		{
			commands.push([
				"-Dlinux",
				"-Dtoolchain=linux",
				"-Dxcompile",
				"-DBINDIR=LinuxArm64",
				"-DHXCPP_ARM64"
			]);
		}
		else if (targetFlags.exists('rpi') && System.hostArchitecture == ARM64 )
'@
    }
)

Patch-File $linuxPlatformHx 'commandExistsOnPath' @(
    @{
        Find = @'
	private function generateWaylandProtocols():Void
	{
'@
        Replace = @'
	private function commandExistsOnPath(command:String):Bool
	{
		var pathEnv = Sys.getEnv("PATH");
		if (pathEnv == null) return false;

		var isWindows:Bool = System.hostPlatform == WINDOWS;
		var sep:String = isWindows ? ";" : ":";
		var exts:Array<String> = isWindows ? ["", ".exe", ".bat", ".cmd"] : [""];

		for (dir in pathEnv.split(sep))
		{
			if (dir == "") continue;

			for (ext in exts)
			{
				if (FileSystem.exists(Path.combine(dir, command + ext)))
				{
					return true;
				}
			}
		}

		return false;
	}

	private function generateWaylandProtocols():Void
	{
'@
    },
    @{
        Find = @'
		if (FileSystem.exists(waylandProtocolsPath))
		{
			var xmls:Array<String> = FileSystem.readDirectory(waylandProtocolsPath);
'@
        Replace = @'
		// `wayland-scanner` is a Linux-native tool with no Windows build; when cross-compiling from
		// Windows, skip Wayland protocol codegen rather than aborting the whole build - SDL still
		// falls back to X11/XWayland at runtime. Checked via a plain PATH scan (not Sys.command)
		// since attempting to launch a genuinely missing executable behaves inconsistently here.
		if (FileSystem.exists(waylandProtocolsPath) && commandExistsOnPath("wayland-scanner"))
		{
			var xmls:Array<String> = FileSystem.readDirectory(waylandProtocolsPath);
'@
    }
)

$linuxToolchainXml = Join-Path $repoRoot '.haxelib\hxcpp\git\toolchain\linux-toolchain.xml'
Patch-File $linuxToolchainXml 'HXCPP_XLINUX_ARM64_CXX' @(
    @{
        Find = @'
<section if="xcompile" >
   <section if="HXCPP_M64">
      <set name="CXX" value="${HXCPP_XLINUX64_CXX}" />
      <set name="HXCPP_STRIP" value="${HXCPP_XLINUX64_STRIP}" />
      <set name="HXCPP_AR" value="${HXCPP_XLINUX64_AR}" />
      <set name="HXCPP_RANLIB" value="${HXCPP_XLINUX64_RANLIB}" />
   </section>
   <section unless="HXCPP_M64">
      <set name="CXX" value="${HXCPP_XLINUX32_CXX}" />
      <set name="HXCPP_STRIP" value="${HXCPP_XLINUX32_STRIP}" />
      <set name="HXCPP_AR" value="${HXCPP_XLINUX32_AR}" />
      <set name="HXCPP_RANLIB" value="${HXCPP_XLINUX32_RANLIB}" />
   </section>
   <section if="rpi">
'@
        Replace = @'
<section if="xcompile" >
   <section if="HXCPP_ARM64">
      <set name="CXX" value="${HXCPP_XLINUX_ARM64_CXX}" />
      <set name="HXCPP_STRIP" value="${HXCPP_XLINUX_ARM64_STRIP}" />
      <set name="HXCPP_AR" value="${HXCPP_XLINUX_ARM64_AR}" />
      <set name="HXCPP_RANLIB" value="${HXCPP_XLINUX_ARM64_RANLIB}" />
   </section>
   <section if="HXCPP_M64" unless="HXCPP_ARM64">
      <set name="CXX" value="${HXCPP_XLINUX64_CXX}" />
      <set name="HXCPP_STRIP" value="${HXCPP_XLINUX64_STRIP}" />
      <set name="HXCPP_AR" value="${HXCPP_XLINUX64_AR}" />
      <set name="HXCPP_RANLIB" value="${HXCPP_XLINUX64_RANLIB}" />
   </section>
   <section unless="HXCPP_M64">
      <section unless="HXCPP_ARM64">
         <set name="CXX" value="${HXCPP_XLINUX32_CXX}" />
         <set name="HXCPP_STRIP" value="${HXCPP_XLINUX32_STRIP}" />
         <set name="HXCPP_AR" value="${HXCPP_XLINUX32_AR}" />
         <set name="HXCPP_RANLIB" value="${HXCPP_XLINUX32_RANLIB}" />
      </section>
   </section>
   <section if="rpi">
'@
    }
)

$openalConfigH = Join-Path $repoRoot '.haxelib\lime\git\project\lib\custom\openal\include\platforms\linux\config.h'
Patch-File $openalConfigH 'x86/x86_64 only' @(
    @{
        Find = @'
/* Define if we have cpuid.h */
#define HAVE_CPUID_H

/* Define if we have intrin.h */
/* #define HAVE_INTRIN_H */

/* Define if we have guiddef.h */
/* #define HAVE_GUIDDEF_H */

/* Define if we have GCC's __get_cpuid() */
#define HAVE_GCC_GET_CPUID
'@
        Replace = @'
/* Define if we have cpuid.h - x86/x86_64 only, <cpuid.h> doesn't exist on other GCC targets (e.g. aarch64) */
#if defined(__i386__) || defined(__x86_64__)
#define HAVE_CPUID_H
#endif

/* Define if we have intrin.h */
/* #define HAVE_INTRIN_H */

/* Define if we have guiddef.h */
/* #define HAVE_GUIDDEF_H */

/* Define if we have GCC's __get_cpuid() - x86/x86_64 only */
#if defined(__i386__) || defined(__x86_64__)
#define HAVE_GCC_GET_CPUID
#endif
'@
    }
)

$buildToolHx = Join-Path $repoRoot '.haxelib\hxcpp\git\tools\hxcpp\BuildTool.hx'
Patch-File $buildToolHx 'else if (defines.exists("linux"))' @(
    @{
        Find = @'
         if (defines.exists("rpi"))
         {
            defines.set("toolchain","linux");
            defines.set("xcompile","1");
            defines.set("linux","linux");
            defines.set("rpi","1");
            defines.set("hardfp","1");
            defines.set("BINDIR", "RPi");
         }
         else
         {
            set64(defines,m64,arm64);
            defines.set("windows","windows");
'@
        Replace = @'
         if (defines.exists("rpi"))
         {
            defines.set("toolchain","linux");
            defines.set("xcompile","1");
            defines.set("linux","linux");
            defines.set("rpi","1");
            defines.set("hardfp","1");
            defines.set("BINDIR", "RPi");
         }
         else if (defines.exists("linux"))
         {
            set64(defines,m64,arm64);
            defines.set("linux","linux");
            defines.set("toolchain","linux");
            defines.set("xcompile","1");

            if (arm64 || defines.exists("HXCPP_LINUX_ARM64"))
            {
               defines.set("noM32","1");
               defines.set("noM64","1");
               defines.set("HXCPP_ARM64","1");
               m64 = true;
            }

            defines.set("BINDIR", arm64 ? "LinuxArm64" : m64 ? "Linux64":"Linux");
         }
         else
         {
            set64(defines,m64,arm64);
            defines.set("windows","windows");
'@
    }
)


Write-Host ""
Write-Host "Recompiling lime's run.n and hxcpp's hxcpp.n from patched source..."

Push-Location (Join-Path $repoRoot '.haxelib\lime\git\tools')

$formatInstalled = (haxelib list format) -match '^format:'
if (-not $formatInstalled) { haxelib install format }
haxe tools.hxml
haxe run.hxml
Pop-Location

Push-Location (Join-Path $repoRoot '.haxelib\hxcpp\git\tools\hxcpp')
haxe compile.hxml
Pop-Location

Write-Host ""
Write-Host "Done. Build ARM64 Linux with, e.g.:"
Write-Host "haxelib run lime build linux -arm64 -release"
Write-Host "You must have an aarch64-linux-gnu-* toolchain on PATH."

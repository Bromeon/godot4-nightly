# Constants
repo="Bromeon/godot4-nightly"
token="SECRET"
exe="bin/godot.windows.tools.64.exe"

# Exit when any command fails
set -e

# Check if clean
git diff --quiet --exit-code || {
	echo "Repo contains uncommitted changes; abort."
	echo ""
	git status --untracked-files=no
	exit 1
}

# Get current version, if available
oldGodotVer=$($exe --version | xargs || true)
if [ -n "$oldGodotVer" ]
then
	oldGitSha=$(echo $oldGodotVer | sed -E "s/.+custom_build\.//")
	date=$(date "+%Y-%m-%d")
	oldDir="bin/[$date]-windows-editor-$oldGitSha"
	echo "Archive previous binaries to $oldDir..."
	echo ""
	mkdir -p "$oldDir"
	mv bin/godot.windows.tools.64.* "$oldDir/"
	
	# ./dir/* syntax means the files (*) are added without path prefix
	# -aoa: overwrite all;   -mmt12: 12 threads;   -sdel: delete after archiving (only files, not dir)
	7z a "$oldDir.7z" "./$oldDir/*" -aoa -mmt12 -sdel
	rm -r $oldDir
else
	echo "No previous Godot version found; nothing to archive."
	echo ""
	oldGitSha="(none)"
fi


# Find URL with latest artifact named 'godot-windows'
url=$(curl "https://api.github.com/repos/$repo/actions/artifacts" | jq ".artifacts[] | select(.name==\"godot-windows\") | .archive_download_url" | head -n 1 | sed 's/\"//g')

# Download (with redirect) and extract
curl -L -H "Accept: application/vnd.github+json" -H "Authorization: token $token" "$url" --output archive.zip

# -y: yes;   -o: output dir;   -mmt12: 12 threads;   -sdel: delete after archiving
7z x archive.zip -y -obin -mmt12 -sdel

# Run godot to find out version
godotVer=$($exe --version | xargs)
gitSha=$(echo $godotVer | sed -E "s/.+custom_build\.//")

echo ""
echo "Godot version is $gitSha; reset..."
echo "  (raw: $godotVer)"
echo ""

git fetch
git reset --hard $gitSha

echo ""
echo "Successfully downloaded and updated $oldGitSha -> $gitSha."

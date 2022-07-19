# Exit when any command fails
set -e

# Check if clean
git diff --quiet --exit-code || {
	echo "Repo contains uncommitted changes; abort."
	echo ""
	git status --untracked-files=no
	exit 1
}

# Constants
repo="Bromeon/godot4-nightly"
token="SECRET"
exe="bin/godot.windows.tools.64.exe"

# Find URL with latest artifact named 'godot-windows'
url=$(curl "https://api.github.com/repos/$repo/actions/artifacts" | jq ".artifacts[] | select(.name==\"godot-windows\") | .archive_download_url" | head -n 1 | sed 's/\"//g')

# Download (with redirect) and extract
curl -L -H "Accept: application/vnd.github+json" -H "Authorization: token $token" "https://api.github.com/repos/$repo/actions/artifacts/302516000/zip" --output archive.zip
7z x archive.zip -y -obin

# Run godot to find out version
#godotVer=$($exe --version || true) # for exit code 255
godotVer=$($exe --version | xargs)
gitSha=$(echo $godotVer | sed -E "s/.+custom_build\.//")

echo ""
echo "Godot version is $gitSha; reset..."
echo "  (raw: $godotVer)"
echo ""

git fetch
git reset --hard $gitSha

echo ""
echo "Successfully downloaded and switched to $gitSha."

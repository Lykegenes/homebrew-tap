#!/bin/sh
VERSION=$1

# check presence of version
if [ -z $VERSION ]; then
	echo "Missing argument with version" >&2
	exit 1
fi

echo "Preparing release $VERSION"

# check presence of tooling
SHASUM=`which shasum`
CURL=`which curl`
[ -n ${SHASUM} ] && [ -n ${CURL} ] || exit 2

# Check if macOS release exists, if it does then it is likely that the Linux one does too
MAC_TAR_URL="https://github.com/dvdmuckle/spc/releases/download/${VERSION}/spc-${VERSION}-darwin-amd64.tar.gz"
LINUX_TAR_URL="https://github.com/dvdmuckle/spc/releases/download/${VERSION}/spc-${VERSION}_linux-amd64.tar.gz"

CHECKVER_CODE=`curl -X HEAD -m 3 -sfw "%{response_code}" ${MAC_TAR_URL}`
if [ $CHECKVER_CODE -ne 302 ]; then
	echo "Version ${VERSION} does not exist" >&2
	exit 3
fi

echo "Fetching Linux sha256"
#LINUX_SHA=$(curl -sLS "${LINUX_SHA_URL}" | cut -f1 -d\ "")
LINUX_SHA=$(curl -sLS "${LINUX_TAR_URL}" | shasum -a 256 | cut -f1 -d\ "")
echo "Fetching macOS sha256"
#MAC_SHA=$(curl -sLS "${MAC_SHA_URL}" | cut -f1 -d\ "")
MAC_SHA=$(curl -sLS "${MAC_TAR_URL}" | shasum -a 256 | cut -f1 -d\ "")

cat > Formula/spc.rb <<FORMULA
class Spc < Formula
  version "${VERSION}"
  desc "A spotify CLI"
  homepage "https://github.com/dvdmuckle/spc"

  bottle :unneeded

  if OS.mac?
    url "https://github.com/dvdmuckle/spc/releases/download/#{version}/spc-#{version}-darwin-amd64.tar.gz"
    sha256 "${MAC_SHA}"
  elsif OS.linux?
    url "https://github.com/dvdmuckle/spc/releases/download/#{version}/spc-#{version}-linux-amd64.tar.gz"
    sha256 "${LINUX_SHA}"
end

  def install
    bin.install "spc"

    output = Utils.safe_popen_read({ "SHELL" => "bash" }, bin/"spc", "completion", "bash")
    (bash_completion/"spc").write output

    output = Utils.safe_popen_read({ "SHELL" => "zsh" }, bin/"spc", "completion", "zsh")
    (zsh_completion/"_spc").write output

end

end
FORMULA

echo "Successfully updated! Check the code before pushing."

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
MAC_TAR_URL="https://github.com/Spotifyd/spotifyd/releases/download/v${VERSION}/spotifyd-macos-full.tar.gz"
LINUX_TAR_URL="https://github.com/Spotifyd/spotifyd/releases/download/v${VERSION}/spotifyd-linux-full.tar.gz"

CHECKVER_CODE=`curl -X HEAD -m 3 -sfw "%{response_code}" ${MAC_TAR_URL}`
if [ $CHECKVER_CODE -ne 302 ]; then
	echo "Version ${VERSION} does not exist" >&2
	exit 3
fi

# The Spotifyd CD generates sha512s, but Homebrew only supports sha256s.
# The URLs for the respective sha512s
#LINUX_SHA_URL="https://github.com/Spotifyd/spotifyd/releases/download/v${VERSION}/spotifyd-linux-full.sha512"
#MAC_SHA_URL="https://github.com/Spotifyd/spotifyd/releases/download/v${VERSION}/spotifyd-macos-full.sha512"

echo "Fetching Linux sha256"
#LINUX_SHA=$(curl -sLS "${LINUX_SHA_URL}" | cut -f1 -d\ "")
LINUX_SHA=$(curl -sLS "${LINUX_TAR_URL}" | shasum -a 256 | cut -f1 -d\ "")
echo "Fetching macOS sha256"
#MAC_SHA=$(curl -sLS "${MAC_SHA_URL}" | cut -f1 -d\ "")
MAC_SHA=$(curl -sLS "${MAC_TAR_URL}" | shasum -a 256 | cut -f1 -d\ "")

cat > Formula/spotifyd.rb <<FORMULA
class Spotifyd < Formula
  version "v${VERSION}"
  desc "A spotify daemon"
  homepage "https://github.com/Spotifyd/spotifyd"

  bottle :unneeded

  if OS.mac?
    url "https://github.com/Spotifyd/spotifyd/releases/download/#{version}/spotifyd-macos-full.tar.gz"
    sha256 "${MAC_SHA}"
  elsif OS.linux?
    url "https://github.com/Spotifyd/spotifyd/releases/download/#{version}/spotifyd-linux-full.tar.gz"
    sha256 "${LINUX_SHA}"
  end

  depends_on "dbus"
  depends_on "portaudio"

  def install
    bin.install "spotifyd"
  end

  plist_options :manual => "spotifyd"

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>WorkingDirectory</key>
          <string>#{HOMEBREW_PREFIX}</string>
          <key>ProgramArguments</key>
          <array>
              <string>#{opt_bin}/spotifyd</string>
              <string>--no-daemon</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>KeepAlive</key>
          <true/>
          <key>ProcessType</key>
          <string>Interactive</string>
      </dict>
      </plist>
    EOS
  end

  test do
    system "#{bin}/spotifyd", "--version"
  end
end
FORMULA

echo "Successfully updated! Check the code before pushing."

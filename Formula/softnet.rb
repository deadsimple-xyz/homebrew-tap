# typed: false
# frozen_string_literal: true

# Pinned from cirruslabs/homebrew-cli (2026-06-01); Homebrew 7 rejects the upstream duplicate macOS requirement.
# Keep the upstream release URL and checksum, with one macOS requirement.
class Softnet < Formula
  desc "Software networking with isolation for Tart"
  homepage "https://github.com/cirruslabs/softnet"
  version "0.19.0"

  url "https://github.com/cirruslabs/softnet/releases/download/0.19.0/softnet.tar.gz"
  sha256 "1612e1296834aae0b6389650c7c5190add1ee8d71474e328691e67679ecda53c"

  define_method(:install) do
    bin.install "softnet"
  end

  depends_on macos: :sequoia

  def caveats
    <<~EOS
      See the Github repository for more information
    EOS
  end
end

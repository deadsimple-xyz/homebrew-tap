# typed: false
# frozen_string_literal: true

# Pinned from cirruslabs/homebrew-cli (2026-06-01); Homebrew 7 rejects the upstream duplicate macOS requirement.
# Keep the upstream release URL and checksum, with one macOS requirement.
class Tart < Formula
  desc "Run macOS and Linux VMs on Apple Hardware"
  homepage "https://github.com/cirruslabs/tart"
  version "2.32.1"
  license "Fair Source"

  depends_on "deadsimple-xyz/tap/softnet"

  url "https://github.com/cirruslabs/tart/releases/download/2.32.1/tart.tar.gz"
  sha256 "8554ab4f7fc12afe52f9b7e3093a935673cbac737a83973d2db7a0683c814529"

  define_method(:install) do
    libexec.install Dir["*"]
    bin.write_exec_script "#{libexec}/tart.app/Contents/MacOS/tart"
  end

  depends_on macos: :ventura
  def post_install
    generate_completions_from_executable(libexec/"tart.app/Contents/MacOS/tart", "--generate-completion-script")
  end

end

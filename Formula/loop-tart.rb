# Loop's pinned Tart runtime. Its keg and opt path stay separate from other taps' Tart installations.
class LoopTart < Formula
  desc "Tart VM runtime pinned for Loop workers"
  homepage "https://github.com/openai/tart"
  url "https://github.com/openai/tart/releases/download/2.37.0/tart.tar.gz"
  sha256 "d531752c4dad5d4214ac7ff540cefc2647df1fca2338d413d3c01754f54b356b"
  license "Fair Source"

  depends_on arch: :arm64
  depends_on macos: :sequoia
  keg_only "Loop uses its own pinned Tart and Softnet without replacing other installations"

  resource "softnet" do
    url "https://github.com/openai/softnet/releases/download/0.23.0/softnet.tar.gz"
    sha256 "b5daa4e5efaef3c2716f872dcda3961a35b2bddcdf03fe630ac3db0ab8156f3e"
  end

  def install
    libexec.install "tart.app", "LICENSE"
    resource("softnet").stage { (libexec/"softnet").install "softnet" }
    (bin/"tart").write <<~SH
      #!/bin/bash
      export PATH="#{libexec}/softnet:$PATH"
      exec "#{libexec}/tart.app/Contents/MacOS/tart" "$@"
    SH
    chmod 0755, bin/"tart"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tart --version")
  end
end

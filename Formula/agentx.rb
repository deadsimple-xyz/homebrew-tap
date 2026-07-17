class Agentx < Formula
  desc "Dead-simple CLI wrapping the local claude and codex agents"
  homepage "https://github.com/deadsimple-xyz/agent-x"
  url "https://github.com/deadsimple-xyz/agent-x.git", tag: "v0.1.0", revision: "17d55116efdd97ceed86e69f17404d1a33f54727"
  version "0.1.0"
  license "MIT"

  def install
    bin.install "agentx.py" => "agentx"
  end

  test do
    assert_match "usage", shell_output("#{bin}/agentx --help")
  end
end

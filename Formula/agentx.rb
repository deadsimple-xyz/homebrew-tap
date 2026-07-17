class Agentx < Formula
  desc "Dead-simple CLI wrapping the local claude and codex agents"
  homepage "https://github.com/deadsimple-xyz/agent-x"
  url "git@github.com:deadsimple-xyz/agent-x.git", using: :git, revision: "17d55116efdd97ceed86e69f17404d1a33f54727", tag: "v0.1.0"
  version "0.1.0"
  license "MIT"

  def install
    bin.install "agentx.py" => "agentx"
  end

  test do
    assert_match "usage", shell_output("#{bin}/agentx --help")
  end
end

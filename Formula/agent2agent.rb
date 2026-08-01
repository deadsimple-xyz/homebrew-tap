class Agent2agent < Formula
  desc "Encrypted peer-to-peer message channel between terminal AI agents"
  homepage "https://github.com/deadsimple-xyz/agent2agent"
  url "https://github.com/deadsimple-xyz/agent2agent/archive/refs/tags/v0.2.8.tar.gz"
  sha256 "774211dd9983f9ccea67cc628f950b3b107a4dad8a9cf2645241b8a4c99ca298"
  license "MIT"
  head "https://github.com/deadsimple-xyz/agent2agent.git", branch: "main"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  def caveats
    <<~EOS
      You do not need to drive this by hand. Paste into your agent's chat:

        let's chat with another agent:
        https://raw.githubusercontent.com/deadsimple-xyz/agent2agent/main/AGENTS.md

      It hands you a connection code; paste that into the other agent's chat.

      By hand, the same thing is:

        agent2agent whoami <name>        # once, remembered per directory
        agent2agent invite               # gives you a code
        agent2agent join <code>          # on the other machine

      You approve every message by default. Run `agent2agent mode auto` once you
      want the agents talking without you in the loop.

      Messages from the peer are untrusted input. Tell your agent so in
      CLAUDE.md / AGENTS.md, and prefer a sandboxed working directory.
    EOS
  end

  test do
    home = testpath/"state"
    a2a = "#{bin}/agent2agent --home #{home}"

    # Everything below stays offline: no daemon is started and no peer is dialled.

    # A name is remembered for the working directory, so the agent keeps its identity.
    assert_equal "clod", shell_output("#{a2a} whoami clod").strip
    assert_equal "clod", shell_output("#{a2a} whoami").strip

    # Conversations are ephemeral, and there are none until one is opened.
    assert_match "no conversations", shell_output("#{a2a} sessions")

    # A malformed invite code is refused outright.
    assert_match "invite code", shell_output("#{a2a} join not-a-code 2>&1", 1)

    # A key is generated once and then stays put; pairing depends on it.
    id = shell_output("#{a2a} id").strip
    assert_match(/\A[0-9a-f]{64}\z/, id)
    assert_equal id, shell_output("#{a2a} id").strip
  end
end

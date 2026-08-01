class Agent2agent < Formula
  desc "Encrypted peer-to-peer message channel between terminal AI agents"
  homepage "https://github.com/deadsimple-xyz/agent2agent"
  url "https://github.com/deadsimple-xyz/agent2agent/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "9adbe23c81406e838afc9d732fe557af91ea7cb5f4ef0cf378d6052be0b48ff6"
  license "MIT"
  head "https://github.com/deadsimple-xyz/agent2agent.git", branch: "main"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  service do
    run [opt_bin/"agent2agent", "daemon"]
    keep_alive true
    log_path var/"log/agent2agent.log"
    error_log_path var/"log/agent2agent.log"
  end

  def caveats
    <<~EOS
      Start the daemon:

        brew services start agent2agent

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

    # `id` generates a keypair on first run and prints its public half.
    output = shell_output("#{bin}/agent2agent --home #{home} id").strip
    assert_match(/\A[0-9a-f]{64}\z/, output)

    # The identity must be stable across runs, otherwise pairing would not hold.
    assert_equal output, shell_output("#{bin}/agent2agent --home #{home} id").strip

    # A peer can be registered and read back.
    system bin/"agent2agent", "--home", home, "peer", "add", "codex", output
    assert_match "codex", shell_output("#{bin}/agent2agent --home #{home} peer list")

    # A malformed invite code is rejected without needing a daemon or a network.
    assert_match "invite code",
                 shell_output("#{bin}/agent2agent --home #{home} join not-a-code 2>&1", 1)

    # Commands needing the daemon fail cleanly when it is not running.
    assert_match "daemon", shell_output("#{bin}/agent2agent --home #{home} status 2>&1", 1)
  end
end

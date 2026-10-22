# Rendered by scripts/render-homebrew-formula.mjs from the released source archive metadata.
require "download_strategy"
require "utils/github/api"

# The release asset lives on a private repository. The declared url is the asset's browser url; at fetch
# time the release is read by tag through the GitHub REST API with Homebrew's own GitHub credential, and the
# asset is downloaded from its API url. `sha256` still pins the bytes.
class LoopReleaseDownloadStrategy < CurlDownloadStrategy
  ASSET_URL = %r{\Ahttps://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/([^/]+)\z}

  private

  def resolve_url_basename_time_file_size(url, timeout: nil)
    return super if url.start_with?("#{GitHub::API_URL}/")

    # The API url redirects to a short-lived storage url; Homebrew downloads that resolved url and drops
    # the Authorization header on the host change.
    super(loop_asset_api_url(url), timeout:)
  end

  def loop_asset_api_url(url)
    @loop_asset_api_url ||= begin
      match = ASSET_URL.match(url)
      raise CurlDownloadStrategyError.new(url, "loop_release_asset_url_invalid") unless match

      owner, repository, tag, asset = match.captures
      token = GitHub::API.credentials
      if token.blank?
        raise CurlDownloadStrategyError.new(
          url, "loop_release_download_unauthenticated: sign in to GitHub with `gh auth login`, then run brew again"
        )
      end

      # The release's own `assets` array was measured EMPTY on a private-repository release whose assets were
      # uploaded and listed by the release's assets endpoint (loop-v0.1.0, 23 Sep 2026), so the assets are read
      # from that endpoint, by the release id the tag resolves to.
      base = "#{GitHub::API_URL}/repos/#{owner}/#{repository}/releases"
      release = GitHub::API.open_rest("#{base}/tags/#{tag}")
      assets = GitHub::API.open_rest("#{base}/#{release.fetch("id")}/assets?per_page=100")
      found = assets.find { |candidate| candidate["name"] == asset }
      raise CurlDownloadStrategyError.new(url, "loop_release_asset_missing: #{asset} on #{tag}") if found.nil?

      meta[:headers] = ["Authorization: Bearer #{token}", "Accept: application/octet-stream"]
      found.fetch("url")
    end
  end
end

class Loop < Formula
  desc "GitHub-native product delivery with disposable Actions workers"
  homepage "https://github.com/deadsimple-xyz/loop"
  url "https://github.com/deadsimple-xyz/loop/releases/download/loop-v0.2.52/loop-0.2.52.tar.gz",
      using: LoopReleaseDownloadStrategy
  version "0.2.52"
  sha256 "f7d3977c783a78f8c5bdb531919d1d23ed5d54e93092131d83e5555c9a7b02c8"

  depends_on arch: :arm64
  depends_on :macos
  depends_on "bash"
  depends_on "curl"
  depends_on "jq"
  depends_on "openssl@3"
  depends_on "node@22"
  depends_on "gh"

  resource "tart" do
    url "https://github.com/openai/tart/releases/download/2.40.1/tart.tar.gz"
    sha256 "363e2701154a8155cbc1bb6d845430c9b42697d2a186bc49574471ca2877db46"
  end

  def install
    libexec.install Dir.glob("*", File::FNM_DOTMATCH).reject { |path| [".", ".."].include?(path) }
    bin.install_symlink libexec/"loop"
    resource("tart").stage { (libexec/"loop-tart").install "tart.app", "LICENSE" }
    (libexec/"loop-tart"/"bin").mkpath
    (libexec/"loop-tart"/"bin"/"tart").write <<~SH
      #!/bin/bash
      exec "#{opt_libexec}/loop-tart/tart.app/Contents/MacOS/tart" "$@"
    SH
    chmod 0755, libexec/"loop-tart"/"bin"/"tart"
  end

  def caveats
    <<~EOS
      Join a worker with the host's existing registration settings:
        loop worker join --config /absolute/runner.env macos:1 linux:N
      Source tools use Node22 at #{Formula["node@22"].opt_bin}/node.
      The worker installer manages xyz.deadsimple.loop.tart-runner.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/loop version")
    assert_match "loop worker join", shell_output("#{bin}/loop worker join --help 2>&1", 2)
    assert_match "2.40.1", shell_output("#{opt_libexec}/loop-tart/bin/tart --version")
  end
end

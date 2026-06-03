# Homebrew formula for ATLAS.
#
# Lives in a TAP repo at https://github.com/Abbasi-Alain/homebrew-atlas
# (Formula/atlas.rb). Users install via:
#
#     brew tap Abbasi-Alain/atlas
#     brew install atlas
#
# After a release, update `url`, `sha256`, and `version`. The SHA is
# computed from the GitHub-generated tarball:
#
#     curl -sL https://github.com/Abbasi-Alain/atlas/archive/refs/tags/vX.Y.Z.tar.gz \
#       | shasum -a 256

class Atlas < Formula
  desc "Agentic Harness Standard — 10–30× fewer agent orientation tokens. Zero infrastructure."
  homepage "https://github.com/Abbasi-Alain/atlas"
  url "https://github.com/Abbasi-Alain/atlas/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "5c62697f6a21ebb62487dc901248dc78e5df31905e8cce3b9247ce7a0321e6ff"
  license "MIT"
  version "0.1.0"

  # Pure bash; no compile step.
  depends_on "bash"

  def install
    # Drop the entire source tree under libexec, then write a thin
    # launcher in bin/ that points ATLAS_HOME at libexec so all the
    # template/adapter/hook lookups resolve.
    libexec.install Dir["*"]

    (bin/"atlas").write <<~SH
      #!/usr/bin/env bash
      # atlas — Homebrew launcher. Forwards to the bundled CLI with
      # ATLAS_HOME pointed at the formula's libexec.
      export ATLAS_HOME="#{libexec}"
      exec "#{libexec}/bin/atlas" "$@"
    SH
    chmod 0755, bin/"atlas"
  end

  test do
    # Logo + version string must appear.
    assert_match "atlas v", shell_output("#{bin}/atlas version")
    # `atlas init` should scaffold ATLAS.md in an empty tmpdir.
    Dir.mktmpdir do |dir|
      system bin/"atlas", "init", dir
      assert_predicate File.join(dir, "ATLAS.md"), :exist?
    end
  end
end

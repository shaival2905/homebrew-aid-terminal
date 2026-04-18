class AidaTerminal < Formula
  desc "A.I.D.A. - AI-Integrated Developer Assistant (Just A Rather Intelligent Developer Assistant)"
  homepage "https://github.com/shaival2905/aid-terminal"
  head "https://github.com/shaival2905/aid-terminal.git", branch: "main"
  url "https://github.com/shaival2905/aid-terminal/archive/refs/heads/main.tar.gz"
  license "MIT"

  version "0.1.0"

  depends_on "rust" => :build
  depends_on "cargo" => :build
  depends_on "cmake" => :build
  depends_on "pkg-config" => :build

  def install
    # Build the main terminal
    system "cargo", "build", "--release", "--package", "alacritty"

    # Install the binary
    bin.install "target/release/alacritty" => "aida"

    # Build and install aida-sidecar
    cd "aida-sidecar" do
      system "cargo", "build", "--release"
      bin.install "target/release/aida-sidecar"
    end

    # Install completion scripts
    outpath = buildpath/"out"
    outpath.mkpath
    system "cargo", "completions", "--shell", "bash", "--output", "#{outpath}/aida.bash"
    system "cargo", "completions", "--shell", "zsh", "--output", "#{outpath}/aida.zsh"
    system "cargo", "completions", "--shell", "fish", "--output", "#{outpath}/aida.fish"

    install_completions_shell_scripts
    install_man_page "extra/man/alacritty.1.scd" => "aida.1"

    # Install configuration directory
    (etc/"aida").mkpath
    (etc/"aida"/"config.toml").write <<~TOML
      # A.I.D.A. Configuration

      # NVIDIA NIM API Key
      # Get your key from: https://build.nvidia.com/
      nvidia_nim_api_key = ""

      # AI Model
      model = "meta/llama-3.1-405b-instruct"

      [features]
      command_suggestions = true
      error_explanation = true
      codebase_indexing = true
      autonomous_execution = false
      natural_language = true

      [persistent_memory]
      enabled = true
      auto_save = true

      [real_time_monitoring]
      error_detection = true
      process_tracking = true
      resource_alerts = true
    TOML

    # Install app bundle for macOS
    if OS.mac?
      (prefix/"AIDA.app").mkpath
      (prefix/"AIDA.app"/"Contents"/"MacOS").mkpath
      (prefix/"AIDA.app"/"Contents"/"Resources").mkpath

      # Copy binary
      cp "target/release/alacritty", prefix/"AIDA.app"/"Contents"/"MacOS"/"aida"

      # Create Info.plist
      (prefix/"AIDA.app"/"Contents"/"Info.plist").write <<~PLIST
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleDevelopmentRegion</key>
            <string>en</string>
            <key>CFBundleExecutable</key>
            <string>aida</string>
            <key>CFBundleIdentifier</key>
            <string>com.aida.terminal</string>
            <key>CFBundleName</key>
            <string>A.I.D.A.</string>
            <key>CFBundleDisplayName</key>
            <string>A.I.D.A. Terminal</string>
            <key>CFBundleInfoDictionaryVersion</key>
            <string>6.0</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
            <key>CFBundleShortVersionString</key>
            <string>#{version}</string>
            <key>CFBundleVersion</key>
            <string>#{version}</string>
            <key>LSMinimumSystemVersion</key>
            <string>12.0</string>
            <key>NSHighResolutionCapable</key>
            <true/>
        </dict>
        </plist>
      PLIST
    end
  end

  def post_install
    # Create default config directory if it doesn't exist
    (Pathname.new(HOMEBREW_PREFIX)/"etc"/"aida").mkpath unless (Pathname.new(HOMEBREW_PREFIX)/"etc"/"aida").exist?

    # Setup shell integration
    ohai "Setting up shell integration"

    # Add to PATH
    if (Pathname.new(HOMEBREW_PREFIX)/"bin").exist?
      ohai "A.I.D.A. is now available. Run 'aida' or 'aida-sidecar' to start."
    end

    # Instructions
    ohai "Next steps:"
    puts <<~EOS
      1. Set your NVIDIA NIM API key:
         export NVIDIA_NIM_API_KEY=your_api_key

      2. Add to your ~/.zshrc or ~/.bashrc:
         export NVIDIA_NIM_API_KEY=your_api_key

      3. Launch A.I.D.A.:
         aida              # Terminal emulator
         aida-sidecar      # AI assistant only

      4. Or open the macOS app:
         open #{prefix}/AIDA.app
    EOS
  end

  def caveats
    <<~EOS
      A.I.D.A. - AI-Integrated Developer Assistant

      To enable AI features, set your NVIDIA NIM API key:
        export NVIDIA_NIM_API_KEY=your_api_key

      Get your API key from: https://build.nvidia.com/

      Auto-update is available via:
        aida-update

      For more information, visit:
        #{homepage}
    EOS
  end

  test do
    # Test that the binary runs
    system "#{bin}/aida", "--version"

    # Test that aida-sidecar runs
    system "#{bin}/aida-sidecar", "--help"
  end
end

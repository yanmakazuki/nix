-- Tree-sitter のネイティブパーサーには CLT の既定SDKを使う。
if vim.fn.has("mac") == 1 then
  local clt_sdk = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
  if vim.uv.fs_stat(clt_sdk) then
    vim.env.SDKROOT = clt_sdk
  end
end

require("config.lazy")

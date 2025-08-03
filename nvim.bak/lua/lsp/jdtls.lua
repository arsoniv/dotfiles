-- ~/.config/nvim/lua/lsp/jdtls.lua
local jdtls = require("jdtls")

local home = os.getenv("HOME")
local workspace_dir = home .. "/.local/share/jdtls/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")

local config = {
  cmd = {
    "jdtls",
    "--jvm-arg=-javaagent:" .. home .. "/.local/share/nvim/mason/packages/jdtls/lombok.jar",
    "-data", workspace_dir,
  },
  root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew" }),
}

jdtls.start_or_attach(config)


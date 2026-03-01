--- @sync entry
return {
  entry = function()
    local h = cx.active.current.hovered
    if not h then
      return
    end

    if h.cha.is_dir then
      -- Go to the hovered directory explicitly, then quit.
      -- Using `cd` with the hovered URL avoids the “entered but chdir not synced yet” race.
      ya.emit("cd", { h.url })
      ya.emit("quit", {})
    else
      -- Open hovered file and DO NOT quit
      ya.emit("open", { hovered = true })
    end
  end,
}

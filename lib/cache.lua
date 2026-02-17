local M = {}

local cache = {}
local ttl = 3600 -- 1 hour

---Caches the return value of the given function, if not already cached
---and not past the TTL.
---@param func fun(...): any The function to execute
---@param cache_key string The cache key
---@vararg any Parameters to pass to the function
---@return any # the cached return value of the function
function M.value(func, cache_key, ...)
  local now = os.time()

  -- Check cache
  if cache[cache_key] and (now - cache[cache_key].timestamp) < ttl then
    return cache[cache_key].data
  end

  -- Fetch fresh data
  local data = func(...)

  -- Cache the result
  cache[cache_key] = {
    data = data,
    timestamp = now,
  }

  return data
end

---Caches the return value of the given function if not already cached,
---not past the TTL, and the first return value of the function is
---true (successful).
---@param func fun(...): any The function to execute
---@param cache_key string The cache key
---@vararg any Parameters to pass to the function
---@return boolean success # whether the function was successful
---@return any # the return value that is cached if successful
function M.maybeValue(func, cache_key, ...)
  local now = os.time()

  -- Check cache
  if cache[cache_key] and (now - cache[cache_key].timestamp) < ttl then
    return true, cache[cache_key].data
  end

  -- Fetch fresh data
  local success, data = func(...)

  if not success then
    -- Do not cache, immediately return
    return success, data
  end

  -- Cache the result
  cache[cache_key] = {
    data = data,
    timestamp = now,
  }

  return success, data
end

return M

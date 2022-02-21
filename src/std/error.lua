return function(msg, level)
    level = level or 1
    error(msg, 1 + level)
end

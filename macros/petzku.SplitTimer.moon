-- Copyright (c) 2021 petzku <petzku@zku.fi>

export script_name =        "SplitTimer"
export script_description = "Split lines in selection into shorter segments"
export script_author =      "petzku"
export script_namespace =   "petzku.SplitTimer"
export script_version =     "1.1.0"

havedc, DependencyControl = pcall require, "l0.DependencyControl"
local dep, util, petzku
if havedc
    dep = DependencyControl{{
        'aegisub.util',
        {'petzku.util', version: '0.3.0', url: "https://github.com/petzku/Aegisub-Scripts",
         feed: "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json"},
    }}
    util, petzku = dep\requireModules!
else
    util, petzku = require 'aegisub.util', 'petzku.util'


-- Most matroska demuxers look back up to 10 seconds for events on seek
-- Therefore, any events shorter than 10 seconds are guaranteed to be found
MAX_DURATION = 10000 -- milliseconds

FRAME_GUI = {
    help: {
        class: 'label', label: "How many frames per segment: ",
        x: 0, y: 0
    },
    frames: {
        class: 'intedit', value: 1, name: 'frames'
        x: 1, y: 0
    }
}


calc_end_frames = (frames) -> (start) ->
    temp = aegisub.ms_from_frame frames + aegisub.frame_from_ms start
    -- if no vid loaded, assume 23.976
    temp or start + frames * 24000/1001

calc_end_time = (start) ->
    temp = aegisub.ms_from_frame aegisub.frame_from_ms start + MAX_DURATION
    -- nil if no video loaded
    temp or start + MAX_DURATION

split = (subs, sel, calc) ->
    for si = #sel,1,-1
        i = sel[si]
        line = subs[i]
        
        -- skip iteration if line is at most one split long
        unless line.end_time > calc line.start_time
            continue
        
        k = 1
        st = line.start_time
        et = math.min line.end_time, calc line.start_time
        while st < line.end_time
            new = util.copy line
            new = petzku.transform.retime new, line.start_time - st
            new.start_time = st
            new.end_time = et
            subs.insert i+k, new

            st = et
            et = math.min line.end_time, calc st
            k += 1
        subs.delete i

split_time = (subs, sel) ->
    split subs, sel, calc_end_time

split_frames = (subs, sel) ->
    btn, res = aegisub.dialog.display FRAME_GUI
    if btn
        split subs, sel, calc_end_frames res.frames

macros = {
    {'10 second chunks', "Split line into 10-second-long chunks", split_time},
    {'N frames', "Split line into N-frame-long events (opens GUI)", split_frames}
}

if havedc
    dep\registerMacros macros
else
    for macro in *macros
        name, desc, fun, cond = unpack macro
        aegisub.register_macro script_name..'/'..name, desc, fun, cond

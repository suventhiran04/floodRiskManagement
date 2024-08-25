globals [
  roads
  buildings
  evacuated-humans
  water-fully-spread?
  evacuation-complete-ticks
  humans-in-buildings
  evacuating-cars
  dead-humans
  spread-complete-ticks
  evacuated-boats
  building-types
  total-water-level
  buildings-covered-in-water
  residential-buildings
  commercial-buildings
  landmark-buildings
  special-buildings
  ocupied-buildings
  total-buildings-at-200-ticks
  damage
]

breed [cars car]
breed [humans human]
breed [boats boat]

patches-own [
  road?
  building?
  building-type
  water-depth
  slope-depth
  occupants
]

humans-own [
  speed
  evacuating?
  target-building
  speed
  initial-xcor  ; New variable to store initial x-coordinate
  initial-ycor  ; New variable to store initial y-coordinate

]

cars-own [
  speed
  evacuating?
]

boats-own [
  capacity
  passengers
]

to setup
  clear-all
  resize-world -18 18 -18 18
  set-patch-size 15
  setup-roads
  setup-river
  setup-buildings
  set building-types ["residential" "buildings" "landmark"  "Emergency"]
  setup-river
  setup-slope-depths
  setup-humans
  setup-cars
  setup-boats
  set evacuated-humans 0
  set water-fully-spread? false  ;Initialize to false
  set evacuation-complete-ticks 0
  set spread-complete-ticks 0
  set humans-in-buildings 0
  set evacuating-cars 0
  set dead-humans 0
  set evacuated-boats 0
  set total-water-level 0
  set buildings-covered-in-water 0
  count-buildings
  ; Setup beach
  if beach [ set sea-damage-reduce sea-damage-reduce ]


  reset-ticks
end

to update-total-water-level
  set total-water-level rainfall-level + lake-height + river-height
end

to setup-slope-depths
  ask patches [
    if pcolor != blue [ ; Exclude sea area
      set slope-depth (random 16) * 0.1  ; Random value from 0 to 1.5 in increments of 0.1
    ]
  ]
  ask patches with [road?] [
    let random-num random-float 1
    ifelse random-num < 0.1 [  ; 10% chance of Random value between 0 and 0.5
      set slope-depth random-float 0.5
    ] [
      ifelse random-num < 0.5 [  ; 40% chance of  Random value between 0.5 and 1
        set slope-depth 0.5 + random-float 0.5
      ] [  ; 50% chance Random value between 1 and 1.5
        set slope-depth 1 + random-float 0.5
      ]
    ]
  ]
end

to setup-roads
  ask patches [
    set pcolor white
    set road? false
  ]
  ask patches with [pxcor = 0 or pycor = 0] [
    set pcolor [139 165 193]
    set road? true
  ]
  ask patches with [
    (pxcor = 0 and pycor >= -18 and pycor <= -1)  ; Road from (0, -25) to (25, -25)
    or
    (pycor = -18 and pxcor >= 0 and pxcor <= 18)  ; Road from (0, -25) to (25, -25)
    or
    (pxcor = -18 and pycor >= 0 and pycor <= 18)  ; Road from (-25, 0) to (-25, 25)
    or
    (pycor = 25 and pxcor >= -25 and pxcor <= 25)  ; Road from (-25, 25) to (25, 25)
  ] [
    set pcolor [139 165 193]  ; Road color
    set road? true
  ]
end

to setup-buildings
  let potential-building-patches patches with [not road? and pcolor != blue]
  let building-patches n-of 320 potential-building-patches

  ask building-patches [
    set building? true
    set building-type one-of ["residential" "commercial" "landmark"]
    set pcolor (ifelse-value
      building-type = "residential" [[252 249 239]]
      building-type = "commercial" [[232 233 237]]
      ; landmark buildings
      [[206 216 226]])
    set occupants 0  ; Initialize occupants to 0
  ]

  ; Set special buildings
  ask patch 15 15 [ ; Upper right corner
    set building? true
    set building-type "special"
    set pcolor red
    set occupants 0
  ]
  ask patch 10 -8 [ ; Lower right corner
    set building? true
    set building-type "special"
    set pcolor red
    set occupants 0
  ]
end

to count-buildings
  set residential-buildings count patches with [ building-type = "residential"]
  set commercial-buildings count patches with [building-type = "commercial"]
  set landmark-buildings count patches with [building-type = "landmark"]
  set special-buildings count patches with [building-type = "special"]

end

to-report count-residential-buildings
  report residential-buildings
end

to-report count-commercial-buildings
  report commercial-buildings
end

to-report count-landmark-buildings
  report landmark-buildings
end

to-report count-special-buildings
  report special-buildings
end

to-report total-buildings
  report residential-buildings + commercial-buildings + landmark-buildings + special-buildings
end


to setup-river
  ask patches with [
    (pxcor >= -25 and pycor <= 0) and
    (pxcor <= 0 and pycor >= -25) and
    ((pxcor + pycor) <= -25)
  ] [
    set pcolor blue
  ]
end

to setup-humans
  create-humans human-population [
    set color red
    set shape "person"
    set size 0.5
    set speed 0.3 + random-float 0.1
    set evacuating? false
    set target-building nobody
    let valid-spot false
    while [not valid-spot] [
      let potential-patch one-of patches with [pcolor = white or pcolor = [234 192 143] or pcolor = [232 233 237] or pcolor = [252 249 239] or pcolor = red]
      if potential-patch != nobody [
        move-to potential-patch
        set valid-spot true
      ]
    ]
    set initial-xcor xcor
    set initial-ycor ycor
  ]
end


to setup-cars
  create-cars 30 [
    set color black
    set shape "car"
    set size 0.5
    let valid-spot false
    while [not valid-spot] [
      let potential-patch one-of patches with [road?]
      if potential-patch != nobody [
        move-to potential-patch
        set valid-spot true
      ]
    ]
    set speed 1 + random-float 1  ; Random speed between 0.1 and 0.5
    set evacuating? false
  ]
end

to setup-boats
  create-boats 8 [
    set shape "boat 3"
    set color red
    set size 2
    set capacity 5
    set passengers 0
    move-to one-of patches with [pcolor = red]
  ]
end


to move-boats
  ask boats [
    ifelse passengers = 0 [
      ; If empty, move towards occupied buildings
      let target-patch min-one-of patches with [pcolor = [80 35 74]] [distance myself]
      if target-patch != nobody [
        face target-patch
        fd 1
      ]
    ] [
      ; If carrying passengers, move towards exit points
      let exit-point min-one-of (patch-set patch 18 0 patch -18 0 patch 0 18 patch 0 -18) [distance myself]
      face exit-point
      fd 1
      if member? patch-here (patch-set patch 18 0 patch -18 0 patch 0 18 patch 0 -18) [
        set evacuated-humans evacuated-humans + passengers
        set evacuated-boats evacuated-boats + 1  ; Increment evacuated-boats
        set passengers 0
        move-to one-of patches with [pcolor = red]
      ]
    ]
  ]
end

to pickup-humans
  ask boats [
    if passengers < capacity [
      let nearby-building one-of patches in-radius 1 with [pcolor = [80 35 74]]
      if nearby-building != nobody [
        let available-space capacity - passengers
        let humans-to-pickup min (list available-space [occupants] of nearby-building)
        set passengers passengers + humans-to-pickup
        ask nearby-building [
          set occupants occupants - humans-to-pickup
          update-building-color
        ]
      ]
    ]
  ]
end

to go
  update-total-water-level
  move-boats
  pickup-humans
  spread-water2
  check-for-evacuation
  update-buildings-covered-in-water

  ; Check if all humans have been evacuated
  if count patches with [pcolor = [80 35 74]] = 0 [
    stop
  ]

  tick
end



to move-car1
  ; Basic movement for cars
  let target-patch patch-ahead 1
  ifelse target-patch != nobody and [road?] of target-patch [
    fd speed
  ] [
    ; If the car can't move forward, it turns left or right
    ifelse random 2 = 0 [
      left 90
    ] [
      right 90
    ]
  ]
end

to move-car
  ifelse evacuating? [
    let exit find-nearest-car-exit
    if exit != nobody [
      face exit
      let target-patch patch-ahead 1
      ifelse target-patch != nobody and [road?] of target-patch [
        fd speed
      ] [
        ; If the car can't move forward, it turns left or right
        ifelse random 2 = 0 [
          left 90
        ] [
          right 90
        ]
      ]
      if distance exit < 1 [
        die  ; Car has left the region
      ]
    ]
  ] [
    ; Regular movement when not evacuating
    let target-patch patch-ahead 1
    ifelse target-patch != nobody and [road?] of target-patch [
      fd speed
    ] [
      ; If the car can't move forward, it turns left or right
      ifelse random 2 = 0 [
        left 90
      ] [
        right 90
      ]
    ]
  ]
end

to-report find-nearest-car-exit
  let exit-points (patch-set patch 18 0 patch -18 0 patch 0 18 patch 0 -18 patch -18 18 patch 18 -18)
  report min-one-of exit-points with [road?] [distance myself]
end

to go0
  update-total-water-level
  update-buildings-covered-in-water
  ask humans [
    move-human0
  ]
  ask cars [
    move-car
  ]

  spread-water

  set-current-plot "Flood Spread at Low Risk Level"
  plot count patches with [pcolor = [135 206 235]]

  ; Add this block to count blue buildings at 100 ticks
  if ticks = 200 [
    let residential-count count-buildings-by-color [252 249 239]
    let commercial-count count-buildings-by-color [232 233 237]
    let landmark-count count-buildings-by-color [206 216 226]
    let special-count count-buildings-by-color red

    set total-buildings-at-200-ticks (residential-count + commercial-count + landmark-count + special-count)

  ]
    ; Update damage every tick after 200 ticks
  if ticks >= 200 [
    set damage calculate-damage
  ]

  tick
end

to go2
  update-total-water-level
  update-buildings-covered-in-water
  ask humans [
    ifelse evacuating? [
      move-to-target-building2
    ] [
      move-human3
    ]
  ]
  ask cars [
    check-car-evacuation
    move-car
  ]

  spread-water2
  check-for-evacuation

   ; Add this block to count blue buildings at 100 ticks
  if ticks = 200 [
    let residential-count count-buildings-by-color [252 249 239]
    let commercial-count count-buildings-by-color [232 233 237]
    let landmark-count count-buildings-by-color [206 216 226]
    let special-count count-buildings-by-color red
    let purple-count count-buildings-by-color [80 35 74]

    set total-buildings-at-200-ticks (residential-count + commercial-count + landmark-count + special-count + purple-count)
  ]
    ; Update damage every tick after 200 ticks
  if ticks >= 200 [
    set damage calculate-damage
  ]

  ; Check if all humans have evacuated
  if count humans = 0 [
    if evacuation-complete-ticks = 0 [
      set evacuation-complete-ticks ticks  ;; Record the ticks taken for full evacuation
    ]
  ]

  tick
end


to-report total-buildings-200-ticks
  report total-buildings-at-200-ticks
end


to-report count-buildings-by-color [color-to-count]
  report count patches with [pcolor = color-to-count]
end

to go1
  update-total-water-level
  update-buildings-covered-in-water
  ask humans [
    ifelse evacuating? [
      move-to-target-building2
    ] [
      move-human
    ]
  ]
  ask cars [
    check-car-evacuation
    move-car
  ]

  spread-water1
  check-for-evacuation

    ; Add this block to count blue buildings at 100 ticks
  if ticks = 200 [
    let residential-count count-buildings-by-color [252 249 239]
    let commercial-count count-buildings-by-color [232 233 237]
    let landmark-count count-buildings-by-color [206 216 226]
    let special-count count-buildings-by-color red
    let purple-count count-buildings-by-color [80 35 74]


    set total-buildings-at-200-ticks (residential-count + commercial-count + landmark-count + special-count + purple-count)
  ]
    ; Update damage every tick after 200 ticks
  if ticks >= 200 [
    set damage calculate-damage
  ]


  ; Check if all humans have evacuated
  if count humans = 0 [
    if evacuation-complete-ticks = 0 [
      set evacuation-complete-ticks ticks  ;; Record the ticks taken for full evacuation
    ]
  ]

  tick
end


to initial-water
  repeat 10 [
    ask one-of patches with [pcolor != blue and pcolor != red] [
      ask patches in-radius 0 [
        set pcolor yellow
        set water-depth 1  ; Start with maximum depth
      ]
    ]
  ]
end



to spread-water
  update-total-water-level
  let eligible-patches patches with [slope-depth >= 0 and slope-depth <= 0.5 and pcolor != blue and pcolor != red ]
  ask patches with [water-depth > 0] [
    ask neighbors4 with [member? self eligible-patches] [
      let flow-amount 0.1 * ([water-depth] of myself - water-depth)
      if flow-amount > 0 [
        set water-depth water-depth + flow-amount
        ask myself [ set water-depth water-depth - flow-amount ]
      ]
      if water-depth > 0.5 [ set water-depth 0.5 ]
      update-water-appearance
    ]
  ]

  ; increase depth of existing water
  ask patches with [water-depth > 0] [
    set water-depth water-depth + 0.001
    if water-depth > 0.5 [ set water-depth 0.5 ]
    update-water-appearance
  ]
end

to update-water-appearance
  ask patches with [water-depth > 0] [
    set pcolor [135 206 235]
  ]
end

to check-car-evacuation
  if not evacuating? [
    let nearby-water patches in-radius 5 with [water-depth > 0]
    if any? nearby-water [
      set evacuating? true
    ]
  ]
end

to move-human0
  rt random 360; Randomly change direction
  fd speed; Move forward at the human's speed
  if distance (patch initial-xcor initial-ycor) > 10 [; Check if the human is within 10 patches of their initial position
    ; If not, move back to the previous position
    back speed
    rt random 360  ; Try a new direction next time
  ]
  if [road?] of patch-here or [pcolor] of patch-here = blue [; If the human moves onto a road or water, move them back
    back speed
    rt random 360  ; Try a new direction next time
  ]
end

to move-human
  rt random 360 ; Randomly change direction
  fd speed ; Move forward at the human's speed
  if distance (patch initial-xcor initial-ycor) > 10 [ ; Check if the human is within 10 patches of their initial position
    ; If not, move back to the previous position
    back speed
    rt random 360  ; Try a new direction next time
  ]
  if [pcolor] of patch-here = [0 150 255] or [pcolor] of patch-here = blue [ ; If the human moves onto a flood (blue) patch
    ifelse random-float 1 < 0.5 [
      set dead-humans dead-humans + 1  ;; Increment dead-humans counter
      die  ;; Remove the human from the simulation
    ] [
      ; If not dead, move them back and try a new direction
      back speed
      rt random 360  ; Try a new direction next time
    ]
  ]
end

to move-human3
  rt random 360 ; Randomly change direction
  fd speed ; Move forward at the human's speed
  if distance (patch initial-xcor initial-ycor) > 10 [ ; Check if the human is within 10 patches of their initial position
    ; If not, move back to the previous position
    back speed
    rt random 360  ; Try a new direction next time
  ]
  if [pcolor] of patch-here = blue [ ; If the human moves onto a flood (blue) patch
    ifelse random-float 1 < 0.5 [
      set dead-humans dead-humans + 1  ;; Increment dead-humans counter
      die  ;; Remove the human from the simulation
    ] [
      ; If not dead, move them back and try a new direction
      back speed
      rt random 360  ; Try a new direction next time
    ]
  ]
end



to initial-water2
  ask n-of 10 patches with [pcolor != blue and pcolor != red and slope-depth >= 0 and slope-depth <= 1.5] [
    set water-depth 1.5
    set pcolor blue
  ]
end

to spread-water2
  ask patches with [water-depth > 0 and pcolor != red and pcolor != [232 233 237]] [
    let spreading-water min (list water-depth 0.01)
    ask neighbors4 with [
      slope-depth >= 0 and
      slope-depth <= 1.5 and
      pcolor != [80 35 74] and  ; Don't spread to occupied buildings
      pcolor != red and         ; Don't spread to special buildings
      pcolor != [232 233 237]   ; Don't spread to commercial buildings
    ] [
      let target-water-depth 1.5 - slope-depth
      let new-water-depth min (list (water-depth + spreading-water) target-water-depth)
      if new-water-depth > water-depth [
        set water-depth new-water-depth
        update-water-appearance2
      ]
    ]
    set water-depth water-depth - spreading-water
  ]
end

to update-water-appearance2
  if water-depth > 0 and pcolor != red [
    set pcolor [ 3 17 148]
  ]
end



to initial-water1
  repeat 10 [
    ask one-of patches with [pcolor != blue and pcolor != red] [
      ask patches in-radius 0 [
        set pcolor [88 104 245]
        set water-depth 1  ; Start with maximum depth
      ]
    ]
  ]
end

to spread-water1
  update-total-water-level
  ask patches with [water-depth > 0 and pcolor != red and pcolor != [232 233 237]] [
    let spreading-water min (list water-depth 0.01)
    ask neighbors4 with [
      slope-depth >= 0 and
      slope-depth <= 1 and
      pcolor != [80 35 74] and  ; Don't spread to occupied buildings
      pcolor != red and         ; Don't spread to special buildings
      pcolor != [232 233 237]   ; Don't spread to commercial buildings
    ] [
      let target-water-depth 1 - slope-depth
      let new-water-depth min (list (water-depth + spreading-water) target-water-depth)
      if new-water-depth > water-depth [
        set water-depth new-water-depth
        update-water-appearance1
      ]
    ]
    set water-depth water-depth - spreading-water
  ]
end

to update-water-appearance1
  ask patches with [water-depth > 0] [
    set pcolor [88 104 245]
  ]
end


to-report find-nearest-exit
  let exit-points (patch-set patch 18 0 patch -18 0 patch 0 18 patch 0 -18)
  report min-one-of exit-points [distance myself]
end

to check-for-evacuation
  let water-patches patches with [water-depth > 0 ]
  if any? water-patches [
    ask humans with [not evacuating?] [
      if random-float 1 < 0.75 [  ; 95% chance to start evacuating
        set evacuating? true
        ifelse random-float 1 < 0.75 [  ; 95% of evacuating humans go to buildings
          set target-building find-nearest-available-building
        ] [  ; 5% of evacuating humans leave the region
          set target-building find-nearest-exit
        ]
      ]
    ]
  ]
end

to move-to-target-building
  if target-building != nobody [
    face target-building
    fd speed
    if patch-here = target-building [  ; Check if the human is exactly on the target patch
      ifelse member? target-building (patch-set patch 18 0 patch -18 0 patch 0 18 patch 0 -18 ) [
        ; Human has reached one of the exit points
        set evacuated-humans evacuated-humans + 1
        die  ; Remove the human from the simulation
      ] [
        ; Human has reached a building
        ask target-building [
          set occupants occupants + 1
          update-building-color  ; Update color when occupancy changes
        ]
        set evacuated-humans evacuated-humans + 1
        die  ; Remove the human from the simulation
      ]
    ]
  ]
end



to check-for-evacuation2
  let water-patches patches with [water-depth > 0 ]
  if any? water-patches [
    ask humans with [not evacuating?] [
      if random-float 1 < 0.80 [  ; 95% chance to start evacuating
        set evacuating? true
        ifelse random-float 1 < 0.80 [  ; 95% of evacuating humans go to buildings
          set target-building find-nearest-available-building2
        ] [  ; 5% of evacuating humans leave the region
          set target-building find-nearest-exit
        ]
      ]
    ]
  ]
end

to move-to-target-building2
  if target-building != nobody [
    face target-building
    fd speed
    ifelse patch-here = target-building [  ; Check if the human is exactly on the target patch
      ifelse member? target-building (patch-set patch 18 0 patch -18 0 patch 0 18 patch 0 -18) [
        ; Human has reached one of the exit points
        set evacuated-humans evacuated-humans + 1
      ] [
        ; Human has reached a building
        ask target-building [
          set occupants occupants + 1
          update-building-color  ; Update color when occupancy changes
        ]
        set humans-in-buildings humans-in-buildings + 1 ;; Increment the count of humans in buildings
      ]
      die  ; Remove the human from the simulation
    ] [
      ; Human hasn't reached the target yet
      if distance target-building < 1 [
        ifelse member? target-building (patch-set patch 18 0 patch -18 0 patch 0 18 patch 0 -18) [
          ; Human has reached one of the exit points
          set evacuated-humans evacuated-humans + 1
        ] [
          ; Human has reached a building
          move-to target-building
          ask target-building [
            set occupants occupants + 1
          ]
          set humans-in-buildings humans-in-buildings + 1 ;; Increment the count of humans in buildings
        ]
        die  ; Remove the human from the simulation
      ]
    ]
  ]
end


to update-building-color
  if pcolor != red [  ; Don't change color of special (red) buildings
    ifelse occupants > 0 [
      set pcolor [80 35 74]  ; Set to purple if occupied, regardless of occupant count
    ] [
      ; Reset to original color if no occupants
      set pcolor (ifelse-value
        building-type = "residential" [[252 249 239]]
        building-type = "commercial" [[232 233 237]]
        ; landmark buildings
        [[206 216 226]])
    ]
  ]
end

to-report find-nearest-available-building2
  let potential-buildings patches with [building? = true and occupants < 5 and pcolor != red]
  ifelse any? potential-buildings [
    report min-one-of potential-buildings [distance myself]
  ] [
    report nobody
  ]
end

to-report find-nearest-available-building
  let potential-buildings patches with [building? = true and occupants < 5 and pcolor != red]
  ifelse any? potential-buildings [
    report min-one-of potential-buildings [distance myself]
  ] [
    report nobody
  ]
end



to update-buildings-covered-in-water
  set buildings-covered-in-water count patches with [pcolor = [135 206 235] and pcolor = [ 3 17 148] and pcolor = [88 104 245] ]
end

to-report calculate-damage
  ifelse ticks >= 200 [
    report ((total-buildings - total-buildings-at-200-ticks)  * 0.05 * 15000)
  ] [
    report 0  ; No damage calculated before 200 ticks
  ]

    ; Apply damage reduction
  if beach [ set damage (total-buildings - total-buildings-at-200-ticks)  * 0.05 * 15000 * (1 - sea-damage-reduce) ]

end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
773
574
-1
-1
15.0
1
10
1
1
1
0
1
1
1
-18
18
-18
18
0
0
1
ticks
30.0

BUTTON
65
105
128
138
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
40
399
152
432
Run - High Risk
go2
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
34
362
159
395
Maximum Rainfall
initial-water2
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
39
437
152
470
Distribute Boats
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
29
302
168
335
Run - Moderate Risk
go1
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
41
264
157
297
Medium Rainfall
initial-water1
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
44
200
154
233
Run - Low Risk
go0
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
38
163
159
196
Minimum Rainfall
initial-water
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
18
20
190
53
human-population
human-population
100
500
400.0
10
1
NIL
HORIZONTAL

PLOT
795
10
1011
160
Flood Spread at Low Risk Level
Time(30min)
Flood Spread
0.0
50.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count patches with [pcolor = [135 206 235] ]"

MONITOR
1020
21
1181
66
No. of Water spread areas
count patches with [pcolor = [135 206 235]]
17
1
11

PLOT
794
176
1014
326
Flood Spread at Moderate Risk Level
Time(30min)
Flood Spread
0.0
50.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count patches with [pcolor = [88 104 245]]"

MONITOR
1021
168
1184
213
No. of Water Spread Areas
count patches with [pcolor =  [88 104 245]]
17
1
11

MONITOR
1022
225
1200
270
No. of Human Leave the area
evacuated-humans
17
1
11

MONITOR
1023
279
1188
324
No . of Humans in Buildings
humans-in-buildings
17
1
11

MONITOR
812
335
994
380
Time for Evacuation(in 30min)
evacuation-complete-ticks
17
1
11

MONITOR
1025
333
1156
378
No. of Dead Humans
dead-humans
17
1
11

PLOT
795
418
1017
568
Flood Spread at High Risk Level
NIL
NIL
0.0
50.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count patches with [pcolor =  [ 3 17 148]]"

MONITOR
1027
412
1190
457
No. of Water Spread Areas
count patches with [pcolor =  [ 3 17 148]]
17
1
11

MONITOR
1028
465
1207
510
No. of Human Leave the Area
evacuated-humans
17
1
11

MONITOR
1030
515
1192
560
No. of Humans in Buildings
humans-in-buildings
17
1
11

MONITOR
1031
567
1157
612
No.of Dead Humans
dead-humans
17
1
11

MONITOR
1020
81
1185
126
No. of Initial Low Risk Areas
count patches with [pcolor = yellow]
17
1
11

MONITOR
810
583
1010
628
Total Time to Evacuate(in 30min)
evacuated-boats + evacuation-complete-ticks
17
1
11

MONITOR
1242
453
1416
498
Self Evacuation(30min)
evacuation-complete-ticks
17
1
11

MONITOR
1249
507
1412
552
Evacuation Time For Boats
evacuated-boats
17
1
11

SLIDER
17
63
189
96
rainfall-level
rainfall-level
1
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
10
504
182
537
river-height
river-height
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
9
554
181
587
lake-height
lake-height
0
100
50.0
1
1
NIL
HORIZONTAL

PLOT
1253
12
1491
197
Water Levels
Time
Water Level
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot total-water-level"

MONITOR
1329
208
1422
253
Total buildings
total-buildings
17
1
11

MONITOR
1293
261
1447
306
Remaining buildings
total-buildings-200-ticks
17
1
11

MONITOR
1289
313
1454
358
Property Damage Estimate
calculate-damage
17
1
11

SWITCH
434
595
537
628
beach
beach
1
1
-1000

SLIDER
9
600
181
633
sea-damage-reduce
sea-damage-reduce
0
10
5.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

boat 3
false
0
Polygon -2674135 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -1184463 true false 150 34 131 49 145 47 147 48 149 49
Polygon -1184463 true false 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -1184463 true false 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@

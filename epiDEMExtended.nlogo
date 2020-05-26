;; COLOURS LEGENDA
;; people -> white = susceptible, red = infected, green = cured (immune)
;; activities -> orange = leisure-activity, yellow = education-activity, cyan = health-activity, blue = professional-activity, grey = activity closed due to quarantine
;; patches -> black = normal, shades of violet = infected (brighter = high infection "strength" and time left, darker = low infection "strength" and time left)
;; houses -> slightly transparent brown

breed [ people a-person ]   ;; moving individuals
breed [ houses house ]   ;; immobile agents representing the homes of people
breed [ leisure-activities leisure-activity ]   ;; includes food related + free time commercial activities (restaurants, bars + malls, cinemas, parks...)
breed [ education-activities education-activity ]   ;; includes schools and universities
breed [ health-activities health-activity ]   ;; includes hospitals, clinics...
breed [ professional-activities professional-activity ]   ;; includes commercial activities not covered by the previous breeds (factories, banks,
                                                          ;; travel agencies, offices...)

globals
[
  nb-infected-previous  ;; Number of infected people at the previous tick
  beta-n                ;; The average number of new secondary
                        ;; infections per infected this tick
  gamma                 ;; The average number of new recoveries
                        ;; per infected this tick
  r0                    ;; The number of secondary infections that arise
                        ;; due to a single infected introduced in a wholly
                        ;; susceptible population

  ;; observer globals
  ;;initial-people   ;; the number of people in the simulation
  ;;recovery-chance   ;; the probability for a person to recover after the recovery-time
  ;;average-recovery-time   ;; the average time after which each sick person may recover
  ;;environmental-infection?   ;; true if virus diffusion through patches infection is present, false otherwise
  ;;base-patch-infection-chance   ;; the probability for a patch to infect a person, "base" since it'll be scaled depending on how long the patch has been infected for
  ;;patch-infection-decay-time   ;; the number of ticks for which a patch will remain infected
  ;;quarantine-level   ;; a number (0 to 3) determining the current level of quarantine

  ;; lists to define the behaviour cycle of people (see "activities-durations.txt")
  ;; each pair has on the same index related values -> at index 0 are the first activity and its duration, at index 1 are the second activity and its duration and so on
  activities-list-5-14
  durations-list-5-14

  activities-list-15-19
  durations-list-15-19

  activities-list-20-24
  durations-list-20-24

  activities-list-25-39
  durations-list-25-39

  activities-list-40-64
  durations-list-40-64

  activities-list-65-and-over
  durations-list-65-and-over

  ;; percentages to model how families are composed (see "families%.txt")
  parents-25-39-percentage   ;; the percentage of 25-39 being parents (living with children)
  parents-40-64-percentage   ;; the percentage of 40-64 being parents (living with children)
  siblings-percentage   ;; the percentage of siblings in appropriate age classes
  people-20-24-with-parents-percentage   ;; the percentage of 20-24 living with parents
  people-20-24-house-sharing-percentage   ;; the percentage of 20-24 living with another 20-24 (roommates)
  people-25-39-in-a-couple-percentage   ;; the percentage of 25-39 living in a couple, not necessarily parents
  people-40-64-in-a-couple-percentage   ;; the percentage of 40-64 living in a couple, not necessarily parents
  people-65-and-over-in-a-couple-percentage   ;; the percentage of 65 and over living in a couple

  global-productivity   ;; to keep trace of the variations of productivity due to the quarantine
]

patches-own
[
  patch-infected?   ;; true if the patch is infected, false otherwise
  patch-infection-time-left   ;; the number of ticks left for which this patch will remain infected
]

people-own
[
  infected?           ;; If true, the person is infected
  cured?              ;; If true, the person has lived through an infection.
                      ;; They cannot be re-infected.
  susceptible?        ;; Tracks whether the person was initially susceptible
  infection-length    ;; How long the person has been infected
  recovery-time       ;; Time (in hours) it takes before the person has a chance to recover from the infection
  nb-infected         ;; Number of secondary infections caused by an
                      ;; infected person at the end of the tick
  nb-recovered        ;; Number of recovered people at the end of the tick

  age-class   ;; a number (0 to 6) representing one of the seven age classes
  home-patch   ;; the patch representing the house of this person (for now randomly generated)
  school-patch   ;; the patch representing the school of this person (decided at creation)
  work-patch   ;; the patch representing the workplace of this person (decided at creation)

  home-risk   ;; a number representing the risk of contracting the virus at home (varies depending on the age class)
  school-risk   ;; a number representing the risk of contracting the virus at school (varies depending on the age class)
  work-risk   ;; a number representing the risk of contracting the virus at work (varies depending on the age class)
  transports-risk   ;; a number representing the risk of contracting the virus on transports (varies depending on the age class)
  leisure-risk   ;; a number representing the risk of contracting the virus in the free time (varies depending on the age class)
  current-infection-chance   ;; the current infection chance for this particular person, it depends on where the person is

  current-activity-index   ;; a number representing the index (in the proper global cycle list) of the activity the person is doing
  current-activity-time-left   ;; number of ticks left before starting the next activity
  moving?   ;; true if moving towards a target, false otherwise
  target   ;; the current target patch that the person needs to reach
  steps   ;; the number of steps separating the person from the target patch

  ;; booleans to count how many people infected in each way
  initially-infected?
  infected-while-at-home?
  infected-while-at-school?
  infected-while-at-work?
  infected-while-at-leisure?
  infected-while-moving?
]

;; necessarie piu' breed? Molti attributi ripetuti (da' pero' la possibilita' di diversificare gli attributi per tipo di attivita', in caso) (italiano)
leisure-activities-own
[
  kind   ;; a string describing the exact activity
  production-value   ;; a number (0 to 1) determining the productive value of the activity
  smart-working-capability ;; a number (0 to 1) determining how capable of employing work from home an activity would be
]

education-activities-own
[
  kind   ;; a string describing the exact activity
  production-value   ;; a number (0 to 1) determining the productive value of the activity
  smart-working-capability ;; a number (0 to 1) determining how capable of employing work from home an activity would be
]

health-activities-own
[
  kind   ;; a string describing the exact activity
  production-value   ;; a number (0 to 1) determining the productive value of the activity
  smart-working-capability ;; a number (0 to 1) determining how capable of employing work from home an activity would be
]

professional-activities-own
[
  kind   ;; a string describing the exact activity
  production-value   ;; a number (0 to 1) determining the productive value of the activity
  smart-working-capability ;; a number (0 to 1) determining how capable of employing work from home an activity would be
]


;;;
;;; SETUP PROCEDURES
;;;

to setup
  clear-all
  setup-globals
  setup-patches
  setup-activities
  setup-people
  setup-families
  if more-realistic-activities-durations? [ adjust-durations-lists ]
  reset-ticks
end

to setup-globals
  setup-lists
  setup-families-percentages
end

to setup-lists
  initialize-lists-empty
  file-open "activities-durations.txt"
  let activity 0
  let duration 0
  let continue? true

  ;; populating 5-14 lists
  while [ (not file-at-end?) and continue? ] [
    set activity file-read
    set duration file-read
    ifelse (activity != "-" and duration != "-") [
      set activities-list-5-14 (sentence activities-list-5-14 activity)
      set durations-list-5-14 (sentence durations-list-5-14 duration)
    ]
    [ set continue? false ]
  ]
  set continue? true

  ;; populating 15-19 lists
  while [ (not file-at-end?) and continue? ] [
    set activity file-read
    set duration file-read
    ifelse (activity != "-" and duration != "-") [
      set activities-list-15-19 (sentence activities-list-15-19 activity)
      set durations-list-15-19 (sentence durations-list-15-19 duration)
    ]
    [ set continue? false ]
  ]
  set continue? true

  ;; populating 20-24 lists
  while [ (not file-at-end?) and continue? ] [
    set activity file-read
    set duration file-read
    ifelse (activity != "-" and duration != "-") [
      set activities-list-20-24 (sentence activities-list-20-24 activity)
      set durations-list-20-24 (sentence durations-list-20-24 duration)
    ]
    [ set continue? false ]
  ]
  set continue? true

  ;; populating 25-39 lists
  while [ (not file-at-end?) and continue? ] [
    set activity file-read
    set duration file-read
    ifelse (activity != "-" and duration != "-") [
      set activities-list-25-39 (sentence activities-list-25-39 activity)
      set durations-list-25-39 (sentence durations-list-25-39 duration)
    ]
    [ set continue? false ]
  ]
  set continue? true

  ;; populating 40-64 lists
  while [ (not file-at-end?) and continue? ] [
    set activity file-read
    set duration file-read
    ifelse (activity != "-" and duration != "-") [
      set activities-list-40-64 (sentence activities-list-40-64 activity)
      set durations-list-40-64 (sentence durations-list-40-64 duration)
    ]
    [ set continue? false ]
  ]
  set continue? true

  ;; populating >=65 lists
  while [ (not file-at-end?) and continue? ] [
    set activity file-read
    set duration file-read
    ifelse (activity != "-" and duration != "-") [
      set activities-list-65-and-over (sentence activities-list-65-and-over activity)
      set durations-list-65-and-over (sentence durations-list-65-and-over duration)
    ]
    [ set continue? false ]
  ]

  file-close
end

to initialize-lists-empty
  set activities-list-5-14 []
  set durations-list-5-14 []
  set activities-list-15-19 []
  set durations-list-15-19 []
  set activities-list-20-24 []
  set durations-list-20-24 []
  set activities-list-25-39 []
  set durations-list-25-39 []
  set activities-list-40-64 []
  set durations-list-40-64 []
  set activities-list-65-and-over []
  set durations-list-65-and-over []
end

to setup-families-percentages
  file-open "families%.txt"   ;; the file must be well formed and contain the % in order (see the file)
  set parents-25-39-percentage file-read
  set parents-40-64-percentage file-read
  set siblings-percentage file-read
  set people-20-24-with-parents-percentage file-read
  set people-20-24-house-sharing-percentage file-read
  set people-25-39-in-a-couple-percentage file-read
  set people-40-64-in-a-couple-percentage file-read
  set people-65-and-over-in-a-couple-percentage file-read
  file-close
end

to setup-patches
  ask patches [ set patch-infected? false ]
end

to setup-activities
  setup-leisure-activities
  setup-education-activities
  setup-health-activities
  setup-professional-activities
end

to setup-leisure-activities
  let num-activities 0
  let useless 0
  file-open "leisure-activities.txt"
  ;; cycling through the file to count how many activities
  ;; (evitabile se la prima cosa che il file contiene e' il numero delle attivita') (italiano)
  while [ not file-at-end? ]
  [
    ;; can't file-read without doing anything with it so I set a useless variable
    ;; I read 3 times since that's the number of parameters each activity has
    repeat 3 [ set useless file-read ]
    set num-activities num-activities + 1
  ]
  file-close
  ;; re-opening the file allows to read it from the start
  file-open "leisure-activities.txt"
  create-leisure-activities num-activities [
    set shape "circle"
    set color orange
    set kind file-read
    set production-value file-read
    set smart-working-capability file-read
    ;; making sure that activities aren't on the same patch
    setxy-avoiding-collisions
  ]
  file-close
end

to setup-education-activities
  let num-activities 0
  let useless 0
  file-open "education-activities.txt"
  ;; cycling through the file to count how many activities
  ;; (evitabile se la prima cosa che il file contiene e' il numero delle attivita') (italiano)
  while [ not file-at-end? ]
  [
    ;; can't file-read without doing anything with it so I set a useless variable
    ;; I read 3 times since that's the number of parameters each activity has
    repeat 3 [ set useless file-read ]
    set num-activities num-activities + 1
  ]
  file-close
  ;; re-opening the file allows to read it from the start
  file-open "education-activities.txt"
  create-education-activities num-activities [
    set shape "circle"
    set color yellow
    set kind file-read
    set production-value file-read
    set smart-working-capability file-read
    ;; making sure that activities aren't on the same patch
    setxy-avoiding-collisions
  ]
  file-close
end

to setup-health-activities
  let num-activities 0
  let useless 0
  file-open "health-activities.txt"
  ;; cycling through the file to count how many activities
  ;; (evitabile se la prima cosa che il file contiene e' il numero delle attivita') (italiano)
  while [ not file-at-end? ]
  [
    ;; can't file-read without doing anything with it so I set a useless variable
    ;; I read 3 times since that's the number of parameters each activity has
    repeat 3 [ set useless file-read ]
    set num-activities num-activities + 1
  ]
  file-close
  ;; re-opening the file allows to read it from the start
  file-open "health-activities.txt"
  create-health-activities num-activities [
    set shape "circle"
    set color cyan
    set kind file-read
    set production-value file-read
    set smart-working-capability file-read
    ;; making sure that activities aren't on the same patch
    setxy-avoiding-collisions
  ]
  file-close
end

to setup-professional-activities
  let num-activities 0
  let useless 0
  file-open "professional-activities.txt"
  ;; cycling through the file to count how many activities
  ;; (evitabile se la prima cosa che il file contiene e' il numero delle attivita') (italiano)
  while [ not file-at-end? ]
  [
    ;; can't file-read without doing anything with it so I set a useless variable
    ;; I read 3 times since that's the number of parameters each activity has
    repeat 3 [ set useless file-read ]
    set num-activities num-activities + 1
  ]
  file-close
  ;; re-opening the file allows to read it from the start
  file-open "professional-activities.txt"
  create-professional-activities num-activities [
    set shape "circle"
    set color blue
    set kind file-read
    set production-value file-read
    set smart-working-capability file-read
    ;; making sure that activities aren't on the same patch
    setxy-avoiding-collisions
  ]
  file-close
end

to setxy-avoiding-collisions
  ;; this next line is necessary to avoid the last turtle to always remain in (0,0)
  setxy random-xcor random-ycor
  ;; no need to specify that turtles-here can be people since they haven't been created yet
  while [any? other turtles-here] [setxy random-xcor random-ycor]
  move-to patch-here   ;; to move it to the center of the patch
end

to setup-people
  setup-0-4
  setup-5-14
  setup-15-19
  setup-20-24
  setup-25-39
  setup-40-64
  setup-65-and-over
  ;; closing here the files opened in the above functions
  file-close-all
  ;; due to the floating percentages and the truncations, we haven't exactly reached initial-people people -> solve that
  correct-people-num
end

to setup-0-4
  ;; 0-4 age class
  file-open "ageClass%.txt"   ;; file containing the percentage of each age class
  let percent file-read   ;; the file must be well formed and contain the % in order (see the file)
  file-open "riskPerAgeClass.txt"   ;; file containing the virus contraction risk per age class and situation
  let h-risk file-read   ;; the file must be well formed and contain the risks in order (see the file)
  ;; "int" truncates
  create-people int (initial-people * percent / 100)
  [
    set age-class 0
    set home-risk h-risk
    setup-people-common
  ]
end

to setup-5-14
  ;; 5-14 age class
  ;; reopening a file without prior closing doesn't reset the cursor position -> here I'm reading the proper values
  file-open "ageClass%.txt"   ;; file containing the percentage of each age class
  let percent file-read   ;; the file must be well formed and contain the % in order (see the file)
  file-open "riskPerAgeClass.txt"   ;; file containing the virus contraction risk per age class and situation
  ;; the file must be well formed and contain the risks in order (see the file)
  let h-risk file-read
  let s-risk file-read
  let t-risk file-read
  let l-risk file-read
  ;; "int" truncates
  let num-people int (initial-people * percent / 100)
  create-people num-people
  [
    set age-class 1
    set home-risk h-risk
    set school-risk s-risk
    set transports-risk t-risk
    set leisure-risk l-risk
    setup-people-common
  ]
  ;; dividing equally the students in the various schools -> count the students per school -> assign to each of these groups a school patch
  ;; (or we could assign to each of these groups the school id through which obtain the patch later)
  let primary-school-patches [ patch-here ] of education-activities with [ kind = "primary-school" ]
  let num-patches length primary-school-patches
  let people-per-patch int (num-people / num-patches)
  foreach primary-school-patches [ x -> ask n-of people-per-patch people with [ age-class = 1 and school-patch = 0 ] [ set school-patch x ] ]
  ;; to account for the hypothetical remainder
  ask n-of (num-people mod num-patches) people with [ age-class = 1 and school-patch = 0 ] [ set school-patch (one-of primary-school-patches) ]
end

to setup-15-19
  ;; 15-19 age class
  ;; reopening a file without prior closing doesn't reset the cursor position -> here I'm reading the proper values
  file-open "ageClass%.txt"   ;; file containing the percentage of each age class
  let percent file-read   ;; the file must be well formed and contain the % in order (see the file)
  file-open "riskPerAgeClass.txt"   ;; file containing the virus contraction risk per age class and situation
  ;; the file must be well formed and contain the risks in order (see the file)
  let h-risk file-read
  let s-risk file-read
  let t-risk file-read
  let l-risk file-read
  ;; "int" truncates
  let num-people int (initial-people * percent / 100)
  create-people num-people
  [
    set age-class 2
    set home-risk h-risk
    set school-risk s-risk
    set transports-risk t-risk
    set leisure-risk l-risk
    setup-people-common
  ]
  ;; dividing equally the students in the various schools -> count the students per school -> assign to each of these groups a school patch
  ;; (or we could assign to each of these groups the school id through which obtain the patch later)
  let secondary-school-patches [ patch-here ] of education-activities with [ kind = "secondary-school" ]
  let num-patches length secondary-school-patches
  let people-per-patch int (num-people / num-patches)
  foreach secondary-school-patches [ x -> ask n-of people-per-patch people with [ age-class = 2 and school-patch = 0 ] [ set school-patch x ] ]
  ;; to account for the hypothetical remainder
  ask n-of (num-people mod num-patches) people with [ age-class = 2 and school-patch = 0 ] [ set school-patch (one-of secondary-school-patches) ]
end

to setup-20-24
  ;; 20-24 age class
  ;; reopening a file without prior closing doesn't reset the cursor position -> here I'm reading the proper values
  file-open "ageClass%.txt"   ;; file containing the percentage of each age class
  let percent file-read   ;; the file must be well formed and contain the % in order (see the file)
  file-open "riskPerAgeClass.txt"   ;; file containing the virus contraction risk per age class and situation
  ;; the file must be well formed and contain the risks in order (see the file)
  let h-risk file-read
  let s-risk file-read
  let t-risk file-read
  let l-risk file-read
  ;; "int" truncates
  let num-people int (initial-people * percent / 100)
  create-people num-people
  [
    set age-class 3
    set home-risk h-risk
    set school-risk s-risk
    set transports-risk t-risk
    set leisure-risk l-risk
    setup-people-common
  ]
  ;; dividing equally the students in the various schools -> count the students per school -> assign to each of these groups a school patch
  ;; (or we could assign to each of these groups the school id through which obtain the patch later)
  let university-patches [ patch-here ] of education-activities with [ kind = "university" ]
  let num-patches length university-patches
  let people-per-patch int (num-people / num-patches)
  foreach university-patches [ x -> ask n-of people-per-patch people with [ age-class = 3 and school-patch = 0 ] [ set school-patch x ] ]
  ;; to account for the hypothetical remainder
  ask n-of (num-people mod num-patches) people with [ age-class = 3 and school-patch = 0 ] [ set school-patch (one-of university-patches) ]
end

to setup-25-39
  ;; 25-39 age class
  ;; reopening a file without prior closing doesn't reset the cursor position -> here I'm reading the proper values
  file-open "ageClass%.txt"   ;; file containing the percentage of each age class
  let percent file-read   ;; the file must be well formed and contain the % in order (see the file)
  file-open "riskPerAgeClass.txt"   ;; file containing the virus contraction risk per age class and situation
  ;; the file must be well formed and contain the risks in order (see the file)
  let h-risk file-read
  let w-risk file-read
  let t-risk file-read
  let l-risk file-read
  ;; "int" truncates
  let num-people int (initial-people * percent / 100)
  create-people num-people
  [
    set age-class 4
    set home-risk h-risk
    set work-risk w-risk
    set transports-risk t-risk
    set leisure-risk l-risk
    setup-people-common
  ]
  ;; setting work-patches later with the other workers (40-64)
end

to setup-40-64
  ;; 40-64 age class
  ;; reopening a file without prior closing doesn't reset the cursor position -> here I'm reading the proper values
  file-open "ageClass%.txt"   ;; file containing the percentage of each age class
  let percent file-read   ;; the file must be well formed and contain the % in order (see the file)
  file-open "riskPerAgeClass.txt"   ;; file containing the virus contraction risk per age class and situation
  ;; the file must be well formed and contain the risks in order (see the file)
  let h-risk file-read
  let w-risk file-read
  let t-risk file-read
  let l-risk file-read
  ;; "int" truncates
  let num-people int (initial-people * percent / 100)
  create-people num-people
  [
    set age-class 5
    set home-risk h-risk
    set work-risk w-risk
    set transports-risk t-risk
    set leisure-risk l-risk
    setup-people-common
  ]
  ;; considering now all workers (25-39 + 39-64)
  set num-people ((count people with [ age-class = 4 ]) + num-people)
  ;; dividing equally the workers in the various jobs -> count the workers per job -> assign to each of these groups a work patch
  ;; (or we could assign to each of these groups the work id through which obtain the patch later)
  let leisure-patches [ patch-here ] of leisure-activities
  let education-patches [ patch-here ] of education-activities
  let health-patches [ patch-here ] of health-activities
  let professional-patches [ patch-here ] of professional-activities
  ;; "sentence" concats the lists
  let work-patches (sentence leisure-patches education-patches health-patches professional-patches)
  let num-patches length work-patches
  let people-per-patch int (num-people / num-patches)
  foreach work-patches [ x -> ask n-of people-per-patch people with [ (age-class = 4 or age-class = 5) and work-patch = 0 ] [ set work-patch x ] ]
  ;; to account for the hypothetical remainder
  ask n-of (num-people mod num-patches) people with [ (age-class = 4 or age-class = 5) and work-patch = 0 ] [ set work-patch (one-of work-patches) ]
end

to setup-65-and-over
  ;; >=65 age class
  ;; reopening a file without prior closing doesn't reset the cursor position -> here I'm reading the proper values
  file-open "ageClass%.txt"   ;; file containing the percentage of each age class
  let percent file-read   ;; the file must be well formed and contain the % in order (see the file)
  file-open "riskPerAgeClass.txt"   ;; file containing the virus contraction risk per age class and situation
  ;; the file must be well formed and contain the risks in order (see the file)
  let h-risk file-read
  let t-risk file-read
  let l-risk file-read
  ;; "int" truncates
  let num-people int (initial-people * percent / 100)
  create-people num-people
  [
    set age-class 6
    set home-risk h-risk
    set transports-risk t-risk
    set leisure-risk l-risk
    setup-people-common
  ]
end

to correct-people-num
  let people-left (initial-people - count people)
  ;; let's make them of the most probable age-class -> 40-64 and working in a random activity
  create-people people-left
  [
    set age-class 5
    set home-risk ([ home-risk ] of one-of people with [ age-class = 5 ])
    set work-risk ([ work-risk ] of one-of people with [ age-class = 5 ])
    set transports-risk ([ transports-risk ] of one-of people with [ age-class = 5 ])
    set leisure-risk ([ leisure-risk ] of one-of people with [ age-class = 5 ])
    set work-patch ([ work-patch ] of one-of people with [ age-class = 5 ])
    setup-people-common
  ]
end

to setup-people-common
  ;; this will be done later while setupping families
  ;;setxy random-xcor random-ycor
  ;;set home-patch patch-here

  ;; preparing variables to manage movement
  set current-activity-index 0
  set current-activity-time-left 0
  set moving? false

  ;; preparing variables to manage counting how many infected in each way
  set initially-infected? false
  set infected-while-at-home? false
  set infected-while-at-school? false
  set infected-while-at-work? false
  set infected-while-at-leisure? false
  set infected-while-moving? false

  set cured? false
  set infected? false
  set susceptible? true
  set shape "person"
  set color white

  ;; Set the recovery time for each agent to fall on a
  ;; normal distribution around average recovery time
  set recovery-time random-normal average-recovery-time average-recovery-time / 4

  ;; make sure it lies between 0 and 2x average-recovery-time
  if recovery-time > average-recovery-time * 2 [
    set recovery-time average-recovery-time * 2
  ]
  if recovery-time < 0 [ set recovery-time 0 ]

  ;; Each individual has a 5% chance of starting out infected.
  ;; To mimic true KM conditions use "ask one-of turtles" instead.
  if (random-float 100 < 5)
  [
    set infected? true
    set initially-infected? true
    set susceptible? false
    set infection-length random recovery-time
  ]
  assign-color
end

;; Different people are displayed in 3 different colors depending on health
;; White is neither infected nor cured (set at beginning)
;; Green is a cured person
;; Red is an infected person
to assign-color  ;; turtle procedure
  if infected?
    [ set color red ]
  if cured?
    [ set color green ]
end

to setup-families
  let num-parents-25-39 round (count people with [ age-class = 4 ] * parents-25-39-percentage / 100)
  let num-parents-40-64 round (count people with [ age-class = 5 ] * parents-40-64-percentage / 100)
  let parents-25-39 n-of num-parents-25-39 people with [ age-class = 4 ]
  let parents-40-64 n-of num-parents-40-64 people with [ age-class = 5 ]
  create-families-for-0-4 parents-25-39
  create-families-for-5-14 parents-40-64
  create-families-for-15-19 parents-40-64
  create-families-for-20-24 parents-40-64
  create-families-for-remaining-25-39
  create-families-for-remaining-40-64
  create-families-for-65-and-over
end

to create-families-for-0-4 [ parents-25-39 ]
  ;; starting from siblings
  let num-siblings-0-4 int (count people with [ age-class = 0 ] * siblings-percentage / 100)
  let siblings-0-4 n-of num-siblings-0-4 people with [ age-class = 0 ]
  setup-siblings num-siblings-0-4 siblings-0-4 parents-25-39

  ;; moving to single 0-4 child families (remaining 0-4)
  let num-single-children-0-4 (count people with [ age-class = 0 and home-patch = 0 ])
  let single-children-0-4 n-of num-single-children-0-4 people with [ age-class = 0 and home-patch = 0 ]
  setup-single-children num-single-children-0-4 single-children-0-4 parents-25-39
end

to create-families-for-5-14 [ parents-40-64 ]
  ;; starting from siblings
  let num-siblings-5-14 int (count people with [ age-class = 1 ] * siblings-percentage / 100)
  let siblings-5-14 n-of num-siblings-5-14 people with [ age-class = 1 ]
  setup-siblings num-siblings-5-14 siblings-5-14 parents-40-64

  ;; moving to single 5-14 child families (remaining 5-14)
  let num-single-children-5-14 (count people with [ age-class = 1 and home-patch = 0 ])
  let single-children-5-14 n-of num-single-children-5-14 people with [ age-class = 1 and home-patch = 0 ]
  setup-single-children num-single-children-5-14 single-children-5-14 parents-40-64
end

to create-families-for-15-19 [ parents-40-64 ]
  ;; starting from siblings
  let num-siblings-15-19 int (count people with [ age-class = 2 ] * siblings-percentage / 100)
  let siblings-15-19 n-of num-siblings-15-19 people with [ age-class = 2 ]
  setup-siblings num-siblings-15-19 siblings-15-19 parents-40-64

  ;; moving to single 15-19 child families (remaining 15-19)
  let num-single-children-15-19 (count people with [ age-class = 2 and home-patch = 0 ])
  let single-children-15-19 n-of num-single-children-15-19 people with [ age-class = 2 and home-patch = 0 ]
  setup-single-children num-single-children-15-19 single-children-15-19 parents-40-64
end

to create-families-for-20-24 [ parents-40-64 ]
  ;; starting from siblings
  let num-siblings-20-24 int (count people with [ age-class = 3 ] * siblings-percentage / 100)
  let siblings-20-24 n-of num-siblings-20-24 people with [ age-class = 3 ]
  setup-siblings num-siblings-20-24 siblings-20-24 parents-40-64

  ;; moving to single 20-24 child families (subtracting from the 20-24 with parents the already assigned siblings)
  let num-single-children-20-24 int (count people with [ age-class = 3 ] * (people-20-24-with-parents-percentage - siblings-percentage) / 100)
  let single-children-20-24 n-of num-single-children-20-24 people with [ age-class = 3 and home-patch = 0 ]
  setup-single-children num-single-children-20-24 single-children-20-24 parents-40-64

  ;; now handling 20-24 roommates
  let num-20-24-sharing int (count people with [ age-class = 3 ] * people-20-24-house-sharing-percentage / 100)
  let people-20-24-sharing n-of num-20-24-sharing people with [ age-class = 3 and home-patch = 0 ]
  ;; roommates aren't actually a couple but the procedure is the same -> use the same function
  setup-in-a-couple num-20-24-sharing people-20-24-sharing

  ;; the remaining 20-24 live alone
  setup-remaining 3   ;; passing the age-class
end

to create-families-for-remaining-25-39
  ;; starting from couples (subtracting the already assigned parents)
  let num-in-a-couple-25-39 int (count people with [ age-class = 4 ] * (people-25-39-in-a-couple-percentage - parents-25-39-percentage) / 100)
  let people-in-a-couple-25-39 n-of num-in-a-couple-25-39 people with [ age-class = 4 and home-patch = 0 ]
  setup-in-a-couple num-in-a-couple-25-39 people-in-a-couple-25-39

  ;; the remaining 25-39 live alone
  setup-remaining 4   ;; passing the age-class
end

to create-families-for-remaining-40-64
  ;; creating families for the remaining 40-64
  ;; starting from couples (subtracting the already assigned parents)
  let num-in-a-couple-40-64 int (count people with [ age-class = 5 ] * (people-40-64-in-a-couple-percentage - parents-40-64-percentage) / 100)
  let people-in-a-couple-40-64 n-of num-in-a-couple-40-64 people with [ age-class = 5 and home-patch = 0 ]
  setup-in-a-couple num-in-a-couple-40-64 people-in-a-couple-40-64

  ;; the remaining 40-64 live alone
  setup-remaining 5   ;; passing the age-class
end

to create-families-for-65-and-over
  ;; starting from couples
  let num-in-a-couple-65-and-over int (count people with [ age-class = 6 ] * people-65-and-over-in-a-couple-percentage / 100)
  let people-in-a-couple-65-and-over n-of num-in-a-couple-65-and-over people with [ age-class = 6 and home-patch = 0 ]
  setup-in-a-couple num-in-a-couple-65-and-over people-in-a-couple-65-and-over

  ;; the remaining 65 and over live alone
  setup-remaining 6   ;; passing the age-class
end

to setup-siblings [ num-siblings siblings parents ]
  ;; since siblings are 2 by 2, the actual number of houses for them is the following
  let current-houses-num int (num-siblings / 2)
  create-houses current-houses-num [
    setup-houses-common
  ]
  ask n-of int (num-siblings / 2) siblings [
    let my-house one-of houses with [ not any? other people-here ]
    set home-patch [ patch-here ] of my-house
    move-to home-patch
    ;; if siblings remaining I can go on
    ifelse (count siblings with [ home-patch = 0 ]) >= 1 [
      let my-sibling one-of siblings with [ home-patch = 0 ]
      ask my-sibling [
        set home-patch [ patch-here ] of my-house
        move-to home-patch
      ]
      ;; if parents remaining I can go on
      ifelse (count parents with [ home-patch = 0 ]) >= 2 [
        let my-parents n-of 2 parents with [ home-patch = 0 ]
        ask my-parents [
          set home-patch [ patch-here ] of my-house
          move-to home-patch
        ]
      ]
      ;; else no more parents, me and my sibling will be assigned to an already existing family
      [
        ask my-house [ die ]
        set my-house one-of houses with [ any? other people-here ]
        set home-patch [ patch-here ] of my-house
        move-to home-patch
        ask my-sibling [
          set home-patch [ patch-here ] of my-house
          move-to home-patch
        ]
      ]
    ]
    ;; else no more siblings, I'll be assigned to an already existing family
    [
      ask my-house [ die ]
      set my-house one-of houses with [ any? other people-here ]
      set home-patch [ patch-here ] of my-house
      move-to home-patch
    ]
  ]
end

to setup-single-children [ num-single-children single-children parents ]
  let current-houses-num num-single-children
  create-houses current-houses-num [
    setup-houses-common
  ]
  ask single-children [
    let my-house one-of houses with [ not any? other people-here ]
    set home-patch [ patch-here ] of my-house
    move-to home-patch
    ;; if parents remaining I can go on
    ifelse (count parents with [ home-patch = 0 ]) >= 2 [
      let my-parents n-of 2 parents with [ home-patch = 0 ]
      ask my-parents [
        set home-patch [ patch-here ] of my-house
        move-to home-patch
      ]
    ]
    ;; else I'll be assigned to an already existing family
    [
      ask my-house [ die ]
      set my-house one-of houses with [ any? other people-here ]
      set home-patch [ patch-here ] of my-house
      move-to home-patch
    ]
  ]
end

to setup-in-a-couple [ num-in-a-couple people-in-a-couple ]
  ;; since couples are 2 by 2, the actual number of houses for them is the following
  let current-houses-num int (num-in-a-couple / 2)
  create-houses current-houses-num [
    setup-houses-common
  ]
  ask n-of int (num-in-a-couple / 2) people-in-a-couple [
    let my-house one-of houses with [ not any? other people-here ]
    set home-patch [ patch-here ] of my-house
    move-to home-patch
    ;; if people in a couple (of the proper age class) remaining I can go on
    ifelse (count people-in-a-couple with [ home-patch = 0 ]) >= 1 [
      let my-other one-of people-in-a-couple with [ home-patch = 0 ]
      ask my-other [
        set home-patch [ patch-here ] of my-house
        move-to home-patch
      ]
    ]
    ;; else no more people in a couple (of the proper age class), I'll be assigned to an already existing family
    [
      ask my-house [ die ]
      set my-house one-of houses with [ any? other people-here ]
      set home-patch [ patch-here ] of my-house
      move-to home-patch
    ]
  ]
end

to setup-remaining [ class ]
  let current-houses-num count people with [ age-class = class and home-patch = 0 ]
  create-houses current-houses-num [
    setup-houses-common
  ]
  ask people with [ age-class = class and home-patch = 0 ] [
    let my-house one-of houses with [ not any? other people-here ]
    set home-patch [ patch-here ] of my-house
    move-to home-patch
  ]
end

to setup-houses-common
  setxy-avoiding-collisions
  set shape "house"
  set color brown
  set color lput 150 extract-rgb color   ;; makes the colour a bit transparent
end

;; making so that the duration of activities are preponderant compared to the time it took to get to them
to adjust-durations-lists
  let school-distances [ distance school-patch ] of people with [ school-patch != 0 ]
  let work-distances [ distance work-patch ] of people with [ work-patch != 0 ]
  let mean-distance mean sentence school-distances work-distances
  let modified-mean-distance mean-distance / 5
  set durations-list-5-14 map [ x -> int (x * modified-mean-distance) ] durations-list-5-14
  set durations-list-15-19 map [ x -> int (x * modified-mean-distance) ] durations-list-15-19
  set durations-list-20-24 map [ x -> int (x * modified-mean-distance) ] durations-list-20-24
  set durations-list-25-39 map [ x -> int (x * modified-mean-distance) ] durations-list-25-39
  set durations-list-40-64 map [ x -> int (x * modified-mean-distance) ] durations-list-40-64
  set durations-list-65-and-over map [ x -> int (x * modified-mean-distance) ] durations-list-65-and-over
end


;;;
;;; GO PROCEDURES
;;;


to go
  if all? people [ not infected? ]
  [
    stop
  ]

  ;; 0-4 just stay home
  ask people with [ age-class != 0 ] [ move ]
  ask people [ clear-count ]

  if environmental-infection? [
    ask people with [ not infected? and not cured? ] [ maybe-get-infected-environmentally ]
    ask patches with [ patch-infected? ] [ update-patch-infection ]
  ]

  ask people with [ infected? ]
    [ infect
      maybe-recover ]

  if environmental-infection? [
    ask patches [ recolour-patch-based-on-infection ]
  ]

  ;; activities closed due to quarantine become grey
  recolour-activities-based-on-quarantine

  ;; recolouring people depending on their state
  ask people [ assign-color ]

  update-global-productivity

  calculate-r0

  tick
end


to move  ;; turtle procedure
  if age-class = 1 [
    handle-cycle activities-list-5-14 durations-list-5-14
  ]
  if age-class = 2 [
    handle-cycle activities-list-15-19 durations-list-15-19
  ]
  if age-class = 3 [
    handle-cycle activities-list-20-24 durations-list-20-24
  ]
  if age-class = 4 [
    handle-cycle activities-list-25-39 durations-list-25-39
  ]
  if age-class = 5 [
    handle-cycle activities-list-40-64 durations-list-40-64
  ]
  if age-class = 6 [
    handle-cycle activities-list-65-and-over durations-list-65-and-over
  ]
end

to handle-cycle [ activities-list durations-list ]
  ;; if I reached the end of the list, then start over
  if current-activity-index = (length activities-list) [
    set current-activity-index 0
  ]
  let current-activity (item current-activity-index activities-list)
  set current-activity (choose-one-if-necessary current-activity)
  let current-duration (item current-activity-index durations-list)
  ;; either waiting for the end of an activity or the activity ended and I start moving towards the next target
  ifelse not moving? [
    ifelse current-activity-time-left = 0 [
      ;; 95% of the people will choose next target depending on the actual quarantine-level
      ifelse random-float 100 < 95 [
        set target determine-target-depending-on-quarantine quarantine-level current-activity
      ]
      ;; 5% of the people won't follow the law and choose next target as if there was no quarantine
      [
        set target determine-target-depending-on-quarantine 0 current-activity
      ]
      set steps distance target
      face target
      ;; if the next target is different from the patch I'm at, then I'll start moving
      ifelse steps >= 0.5 [
        set moving? true
      ]
      ;; else, no need to move, just wait for the necessary duration
      [
        set current-activity-time-left current-duration
      ]
    ]
    [
      set current-activity-time-left current-activity-time-left - 1
      ;; if I've waited enough, then handle the next activity
      if current-activity-time-left = 0 [
        set current-activity-index current-activity-index + 1
      ]
    ]
  ]
  ;; else branch -> moving = true -> either going towards the target (steps >= 0.5) or I've arrived and I set for how much I'll stay here
  [
    ifelse steps >= 0.5 [
      fd 1
      set steps steps - 1
    ]
    [
      set moving? false
      set current-activity-time-left current-duration
    ]
  ]
end

to-report choose-one-if-necessary [ current-activity ]
  ;; obtain a list with all the activities specified in "current-activity"
  let activities-list produce-activities-list current-activity
  ;; choose an activity randomly
  let random-index random length activities-list
  report item random-index activities-list
end

to-report produce-activities-list [ current-activity ]
  let activities-list []
  ;; if the hyphen is present, then I need to choose among more activities
  ifelse (member? "-" current-activity) [
    ;; NB "position" returns only the index of the first occurrence -> that's why the recursion below works
    let hyphen-position (position "-" current-activity)
    let activity-A (substring current-activity 0 hyphen-position)
    set activities-list (sentence activities-list activity-A)
    let activity-B (substring current-activity (hyphen-position + 1) (length current-activity))
    ;; recursive call to choose between more than two activities if necessary
    set activity-B produce-activities-list activity-B
    report (sentence activities-list activity-B)
  ]
  [ report (sentence activities-list current-activity) ]
end

to-report determine-target-depending-on-quarantine [ level current-activity ]
  ;; setting next target depending on the quarantine-level
  if current-activity = "school" [
    ifelse level = 0 [
      report school-patch
    ]
    [
      ;; level 1 isn't too bad, substituting school with recreation
      ifelse level = 1 [
        report determine-random-recreation-patch
      ]
      ;; else, just go home
      [
        report home-patch
      ]
    ]
  ]
  if current-activity = "work" [
    ifelse level = 0 [
      report work-patch
    ]
    [
      ifelse level = 1 [
        ;; if I work in a school, these were closed at quarantine-level = 1 -> level 1 isn't too bad, substituting school with recreation
        let education-patches ([ patch-here ] of education-activities)
        ifelse (member? work-patch education-patches) [
          report determine-random-recreation-patch
        ]
        [
          report work-patch
        ]
      ]
      [
        ifelse level = 2 [
          ;; if I work in a factory or a hospital/clinic I have to go to work even if quarantine-level = 2
          let factory-patches ([ patch-here ] of professional-activities with [ kind = "factory" ])
          let hospital-patches ([ patch-here ] of health-activities with [ kind = "hospital" or kind = "clinic" ])
          let allowed-patches (sentence factory-patches hospital-patches)
          ifelse (member? work-patch allowed-patches) [
            report work-patch
          ]
          ;; else, just go home
          [
            report home-patch
          ]
        ]
        ;; then level = 3
        [
          ;; if I work in a hospital/clinic I have to go to work even if quarantine-level = 3
          let hospital-patches ([ patch-here ] of health-activities with [ kind = "hospital" or kind = "clinic" ])
          ifelse (member? work-patch hospital-patches) [
            report work-patch
          ]
          ;; else, just go home
          [
            report home-patch
          ]
        ]
      ]
    ]
  ]
  if current-activity = "recreation" [
    ifelse level < 2 [
      report determine-random-recreation-patch
    ]
    ;; else, just go home
    [
      report home-patch
    ]
  ]
  if current-activity = "home" [ report home-patch ]
end

to-report determine-random-recreation-patch
  report [ patch-here ] of one-of leisure-activities
end

to clear-count
  set nb-infected 0
  set nb-recovered 0
end

to maybe-get-infected-environmentally
  ;; if not moving, then I'm inside an activity patch/building -> I'll get infected by people in the same state by simple proximity
  ;; instead, if moving, I can get infected environmentally
  if moving? [
    if ([ patch-infected? ] of patch-here) [
      ;; I decided to mantain a slider for the patch-infection-chance since using the transports risk wouldn't really have been fit
      ;; the "strength" of the environmental infection is scaled depending on how long the patch has been infected for
      let scaled-infection-chance (base-patch-infection-chance * patch-infection-time-left / patch-infection-decay-time)
      if random-float 100 < scaled-infection-chance [
        set infected? true
        set nb-infected (nb-infected + 1)
        set infected-while-moving? true
      ]
    ]
  ]
end

to update-patch-infection
  set patch-infection-time-left patch-infection-time-left - 1
  if patch-infection-time-left = 0 [ set patch-infected? false ]
end

to infect  ;; turtle procedure
  ;; if I'm moving, then I'll only infect moving people, which aren't inside a certain activity patch/building
  ifelse moving? [
    let nearby-uninfected (people-on neighbors) with [ not infected? and not cured? and moving? ]
    if nearby-uninfected != nobody [
      ask nearby-uninfected [
        if random-float 100 < transports-risk [
          set infected? true
          set nb-infected (nb-infected + 1)
          set infected-while-moving? true
        ]
      ]
    ]
  ]
  ;; else, since I'm not moving I must be inside a certain activity patch/building -> infect only people in the same state and with the proper infection
  ;; chance for each person
  [
    let nearby-uninfected (people-on patch-here) with [ not infected? and not cured? and not moving? ]
    ask nearby-uninfected [ set-my-current-infection-chance ]
    if nearby-uninfected != nobody [
      ask nearby-uninfected [
        if random-float 100 < current-infection-chance [
          set infected? true
          set nb-infected (nb-infected + 1)
          set-proper-infected-while-variable
        ]
      ]
    ]
  ]

  ;; maybe infect the patch I'm on
  ;; no need to do that if I'm not moving -> I'll have a chance to infect anyway not moving people on patch-here due to closeness, while moving people
  ;; aren't actually inside the same activity patch/building I'm in, so I shouldn't be able to infect them
  if moving? [
    if environmental-infection? [
      ;; also infecting the patch an infected person is standing on
      ask patch-here [
        if not patch-infected? [
          set patch-infected? true
          set patch-infection-time-left patch-infection-decay-time
        ]
      ]
    ]
  ]
end

to set-my-current-infection-chance
  set current-infection-chance (ifelse-value
    patch-here = home-patch [ home-risk ]
    patch-here = school-patch [ school-risk ]
    patch-here = work-patch [ work-risk ]
    ;; if none of the previous are true, I must anyway be in an activity patch since I'm not moving -> the only possibility left is a leisure activity
    [ leisure-risk ] )
end

to set-proper-infected-while-variable
  (ifelse
    patch-here = home-patch [ set infected-while-at-home? true ]
    patch-here = school-patch [ set infected-while-at-school? true ]
    patch-here = work-patch [ set infected-while-at-work? true ]
    ;; if none of the previous are true, I must anyway be in an activity patch since I'm not moving -> the only possibility left is a leisure activity
    [ set infected-while-at-leisure? true ] )
end

to maybe-recover
  set infection-length infection-length + 1

  ;; If people have been infected for more than the recovery-time
  ;; then there is a chance for recovery
  if infection-length > recovery-time
  [
    if random-float 100 < recovery-chance
    [ set infected? false
      set cured? true
      set nb-recovered (nb-recovered + 1)
    ]
  ]
end

to recolour-patch-based-on-infection
  ifelse not patch-infected? [
    set pcolor black
  ]
  ;; else it's infected, set colour as a shade of violet depending on how long the patch has been infected for (brighter = longer)
  [
    ;; couldn't simply use scale-color even for non infected patches since it generates an exception receiving 0 as patch-infection-time-left
    set pcolor scale-color violet patch-infection-time-left 0 patch-infection-decay-time
  ]
end

to recolour-activities-based-on-quarantine
  if quarantine-level = 0 [
    ask leisure-activities [ set color orange ]
    ask education-activities [ set color yellow ]
    ask health-activities [ set color cyan ]
    ask professional-activities [ set color blue ]
  ]
  if quarantine-level = 1 [
    ask leisure-activities [ set color orange ]
    ask education-activities [ set color grey ]
    ask health-activities [ set color cyan ]
    ask professional-activities [ set color blue ]
  ]
  if quarantine-level = 2 [
    ask leisure-activities [ set color grey ]
    ask education-activities [ set color grey ]
    ask health-activities with [ (kind != "hospital") and (kind != "clinic") ] [ set color grey ]
    ask health-activities with [ (kind = "hospital") or (kind = "clinic") ] [ set color cyan ]
    ask professional-activities with [ kind != "factory" ] [ set color grey ]
    ask professional-activities with [ kind = "factory" ] [ set color blue ]
  ]
  if quarantine-level = 3 [
    ask leisure-activities [ set color grey ]
    ask education-activities [ set color grey ]
    ask health-activities with [ (kind != "hospital") and (kind != "clinic") ] [ set color grey ]
    ask health-activities with [ (kind = "hospital") or (kind = "clinic") ] [ set color cyan ]
    ask professional-activities [ set color grey ]
  ]
end

to update-global-productivity
  let education-productivity sum [ production-value ] of education-activities with [ color != grey ]
  ;; calculating closed activities productivity only if necessary
  if quarantine-level > 0 [
    ;; activities closed due to quarantine have their production value modified depending on their ability to apply smart working
    set education-productivity education-productivity + sum [ production-value * smart-working-capability ] of education-activities with [ color = grey ]
  ]
  let leisure-productivity sum [ production-value ] of leisure-activities with [ color != grey ]
  let professional-productivity sum [ production-value ] of professional-activities with [ color != grey ]
  let health-productivity sum [ production-value ] of health-activities with [ color != grey ]
  ;; calculating closed activities productivity only if necessary
  if quarantine-level > 1 [
    ;; activities closed due to quarantine have their production value modified depending on their ability to apply smart working
    set leisure-productivity leisure-productivity + sum [ production-value * smart-working-capability ] of leisure-activities with [ color = grey ]
    set professional-productivity professional-productivity + sum [ production-value * smart-working-capability ] of professional-activities with [ color = grey ]
    set health-productivity health-productivity + sum [ production-value * smart-working-capability ] of health-activities with [ color = grey ]
  ]

  set global-productivity (leisure-productivity + education-productivity + health-productivity + professional-productivity)
end

to calculate-r0
  let new-infected sum [ nb-infected ] of people
  let new-recovered sum [ nb-recovered ] of people

  ;; Number of infected people at the previous tick:
  set nb-infected-previous
    count people with [ infected? ] +
    new-recovered - new-infected

  ;; Number of susceptibles now:
  let susceptible-t
    initial-people -
    count people with [ infected? ] -
    count people with [ cured? ]

  ;; Initial number of susceptibles:
  let s0 count people with [ susceptible? ]

  ifelse nb-infected-previous < 10
  [ set beta-n 0 ]
  [
    ;; This is beta-n, the average number of new
    ;; secondary infections per infected per tick
    set beta-n (new-infected / nb-infected-previous)
  ]

  ifelse nb-infected-previous < 10
  [ set gamma 0 ]
  [
    ;; This is the average number of new recoveries per infected per tick
    set gamma (new-recovered / nb-infected-previous)
  ]

  ;; Prevent division by 0:
  if initial-people - susceptible-t != 0 and susceptible-t != 0
  [
    ;; This is derived from integrating dI / dS = (beta*SI - gamma*I) / (-beta*SI):
    set r0 (ln (s0 / susceptible-t) / (initial-people - susceptible-t))
    ;; Assuming one infected individual introduced in the beginning,
    ;; and hence counting I(0) as negligible, we get the relation:
    ;; N - gamma*ln(S(0)) / beta = S(t) - gamma*ln(S(t)) / beta,
    ;; where N is the initial 'susceptible' population
    ;; Since N >> 1
    ;; Using this, we have R_0 = beta*N / gamma = N*ln(S(0)/S(t)) / (K-S(t))
    set r0 r0 * s0 ]
end


;; Extending epiDEMBasic, which has the following copyright:
; Copyright 2011 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
644
10
2662
2029
-1
-1
10.0
1
10
1
1
1
0
1
1
1
-100
100
-100
100
1
1
1
hours
30.0

BUTTON
235
208
318
241
setup
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
335
208
418
241
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
46
10
600
43
initial-people
initial-people
200
10000
5000.0
100
1
NIL
HORIZONTAL

PLOT
337
248
631
378
Population
hours
# of people
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Infected" 1.0 0 -2674135 true "" "plot count people with [ infected? ]"
"Not Infected" 1.0 0 -10899396 true "" "plot count people with [ not infected? ]"

PLOT
10
390
329
526
Infection and Recovery Rates
hours
rate
0.0
0.2
0.0
0.2
true
true
"" ""
PENS
"Infection Rate" 1.0 0 -2674135 true "" "plot (beta-n * nb-infected-previous)"
"Recovery Rate" 1.0 0 -10899396 true "" "plot (gamma * nb-infected-previous)"

SLIDER
47
49
316
82
recovery-chance
recovery-chance
10
100
30.0
5
1
NIL
HORIZONTAL

PLOT
10
248
328
378
Cumulative Infected and Recovered
hours
% total pop
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"% infected" 1.0 0 -2674135 true "" "plot (((count people with [ cured? ] + count people with [ infected? ]) / initial-people) * 100)"
"% recovered" 1.0 0 -10899396 true "" "plot ((count people with [ cured? ] / initial-people) * 100)"

SLIDER
332
49
600
82
average-recovery-time
average-recovery-time
50
1000
700.0
10
1
NIL
HORIZONTAL

MONITOR
335
390
388
435
R0
r0
2
1
11

SLIDER
332
127
600
160
patch-infection-decay-time
patch-infection-decay-time
1
20
5.0
1
1
NIL
HORIZONTAL

SWITCH
47
88
239
121
environmental-infection?
environmental-infection?
1
1
-1000

SLIDER
48
166
315
199
quarantine-level
quarantine-level
0
3
0.0
1
1
NIL
HORIZONTAL

SLIDER
47
127
314
160
base-patch-infection-chance
base-patch-infection-chance
0
100
50.0
1
1
NIL
HORIZONTAL

MONITOR
336
441
460
486
Infected while at home
word count people with [ infected-while-at-home? ] \"   (\" (precision (count people with [ infected-while-at-home? ] / (count people with [ cured? ] + count people with [ infected? ] ) * 100) 2) \"%)\"
2
1
11

MONITOR
468
441
596
486
Infected while at school
word count people with [ infected-while-at-school? ] \"   (\" (precision (count people with [ infected-while-at-school? ] / (count people with [ cured? ] + count people with [ infected? ] ) * 100) 2) \"%)\"
2
1
11

MONITOR
337
495
460
540
Infected while at work
word count people with [ infected-while-at-work? ] \"   (\" (precision (count people with [ infected-while-at-work? ] / (count people with [ cured? ] + count people with [ infected? ] ) * 100) 2) \"%)\"
2
1
11

MONITOR
469
495
597
540
Infected while at leisure
word count people with [ infected-while-at-leisure? ] \"   (\" (precision (count people with [ infected-while-at-leisure? ] / (count people with [ cured? ] + count people with [ infected? ] ) * 100) 2) \"%)\"
2
1
11

MONITOR
517
390
636
435
Infected while moving
word count people with [ infected-while-moving? ] \"   (\" (precision (count people with [ infected-while-moving? ] / (count people with [ cured? ] + count people with [ infected? ] ) * 100) 2) \"%)\"
2
1
11

MONITOR
394
390
511
435
Initially infected
word count people with [ initially-infected? ] \"   (\" (precision (count people with [ initially-infected? ] / (count people with [ cured? ] + count people with [ infected? ] ) * 100) 2) \"%)\"
2
1
11

MONITOR
10
533
95
578
Productivity %
word (precision (global-productivity / (sum [ production-value ] of leisure-activities + sum [ production-value ] of education-activities + sum [ production-value ] of health-activities + sum [ production-value ] of professional-activities) * 100) 2) \"%\"
2
1
11

MONITOR
103
533
207
578
Activities closed %
word (precision (count turtles with [ color = grey ] / count turtles with [ breed != people and breed != houses ] * 100) 2) \"%\"
2
1
11

SWITCH
332
88
576
121
more-realistic-activities-durations?
more-realistic-activities-durations?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model simulates the spread of an infectious disease in a closed population. It is an introductory model in the curricular unit called epiDEM (Epidemiology: Understanding Disease Dynamics and Emergence through Modeling). This particular model is formulated based on a mathematical model that describes the systemic dynamics of a phenomenon that emerges when one infected person is introduced in a wholly susceptible population. This basic model, in mathematical epidemiology, is known as the Kermack-McKendrick model.

The Kermack-McKendrick model assumes a closed population, meaning there are no births, deaths, or travel into or out of the population. It also assumes that there is homogeneous mixing, in that each person in the world has the same chance of interacting with any other person within the world. In terms of the virus, the model assumes that there are no latent or dormant periods, nor a chance of viral mutation.

Because this model is so simplistic in nature, it facilitates mathematical analyses and also the calculation of the threshold at which an epidemic is expected to occur. We call this the reproduction number, and denote it as R_0. Simply, R_0 stands for the number of secondary infections that arise as a result of introducing one infected person in a wholly susceptible population, over the course of the infected person's contagious period (i.e. while the person is infective, which, in this model, is from the beginning of infection until recovery).

This model incorporates all of the above assumptions, but each individual has a 5% chance of being initialized as infected. This model shows the disease spread as a phenomenon with an element of stochasticity. Small perturbations in the parameters included here can in fact lead to different final outcomes.

Overall, this model helps users
1) engage in a new way of viewing/modeling epidemics that is more personable and relatable
2) understand how the reproduction number, R_0, represents the threshold for an epidemic
3) think about different ways to calculate R_0, and the strengths and weaknesses in each approach
4) understand the relationship between derivatives and integrals, represented simply as rates and cumulative number of cases, and
5) provide opportunities to extend or change the model to include some properties of a disease that interest users the most.

## HOW IT WORKS

Individuals wander around the world in random motion. Upon coming into contact with an infected person, by being in any of the eight surrounding neighbors of the infected person or in the same location, an uninfected individual has a chance of contracting the illness. The user sets the number of people in the world, as well as the probability of contracting the disease.

An infected person has a probability of recovering after reaching their recovery time period, which is also set by the user. The recovery time of each individual is determined by pulling from an approximately normal distribution with a mean of the average recovery time set by the user.

The colors of the individuals indicate the state of their health. Three colors are used: white individuals are uninfected, red individuals are infected, green individuals are recovered. Once recovered, the individual is permanently immune to the virus.

The graph INFECTION AND RECOVERY RATES shows the rate of change of the cumulative infected and recovered in the population. It tracks the average number of secondary infections and recoveries per tick. The reproduction number is calculated under different assumptions than those of the Kermack McKendrick model, as we allow for more than one infected individual in the population, and introduce aforementioned variables.

At the end of the simulation, the R_0 reflects the estimate of the reproduction number, the final size relation that indicates whether there will be (or there was, in the model sense) an epidemic. This again closely follows the mathematical derivation that R_0 = beta*S(0)/ gamma = N*ln(S(0) / S(t)) / (N - S(t)), where N is the total population, S(0) is the initial number of susceptibles, and S(t) is the total number of susceptibles at time t. In this model, the R_0 estimate is the number of secondary infections that arise for an average infected individual over the course of the person's infected period.

## HOW TO USE IT

The SETUP button creates individuals according to the parameter values chosen by the user. Each individual has a 5% chance of being initialized as infected. Once the model has been setup, push the GO button to run the model. GO starts the model and runs it continuously until GO is pushed again.

Note that in this model each time-step can be considered to be in hours, although any suitable time unit will do.

What follows is a summary of the sliders in the model.

INITIAL-PEOPLE (initialized to vary between 50 - 400): The total number of individuals in the simulation, determined by the user.
INFECTION-CHANCE (10 - 100): Probability of disease transmission from one individual to another.
RECOVERY-CHANCE (10 - 100): Probability of an infected individual to recover once the infection has lasted longer than the person's recovery time.
AVERAGE-RECOVERY-TIME (50 - 300): The time it takes for an individual to recover on average. The actual individual's recovery time is pulled from a normal distribution centered around the AVERAGE-RECOVERY-TIME at its mean, with a standard deviation of a quarter of the AVERAGE-RECOVERY-TIME. Each time-step can be considered to be in hours, although any suitable time unit will do.

A number of graphs are also plotted in this model.

CUMULATIVE INFECTED AND RECOVERED: This plots the total percentage of infected and recovered individuals over the course of the disease spread.
POPULATIONS: This plots the total number of people with or without the flu over time.
INFECTION AND RECOVERY RATES: This plots the estimated rates at which the disease is spreading. BetaN is the rate at which the cumulative infected changes, and Gamma rate at which the cumulative recovered changes.
R_0: This is an estimate of the reproduction number, only comparable to the Kermack McKendrick's definition if the initial number of infected were 1.

## THINGS TO NOTICE

As with many epidemiological models, the number of people becoming infected over time, in the event of an epidemic, traces out an "S-curve." It is called an S-curve because it is shaped like a sideways S. By changing the values of the parameters using the slider, try to see what kinds of changes make the S curve stretch or shrink.

Whenever there's a spread of the disease that reaches most of the population, we say that there was an epidemic. As mentioned before, the reproduction number indicates the number of secondary infections that arise as a result of introducing one infected person in a totally susceptible population, over the course of the infected person's contagious period (i.e. while the person is infected). If it is greater than 1, an epidemic occurs. If it is less than 1, then it is likely that the disease spread will stop short, and we call this an endemic.

## THINGS TO TRY

Try running the model by varying one slider at a time. For example:
How does increasing the number of initial people affect the disease spread?
How does increasing the recovery chance the shape of the graphs? What about changes to average recovery time? Or the infection rate?

What happens to the shape of the graphs as you increase the recovery chance and decrease the recovery time? Vice versa?

Notice the graph Cumulative Infected and Recovered, and Infection and Recovery Rates. What are the relationships between the two? Why is the latter graph jagged?

## EXTENDING THE MODEL

Try to change the behavior of the people once they are infected. For example, once infected, the individual might move slower, have fewer contacts, isolate him or herself etc. Try to think about how you would introduce such a variable.

In this model, we also assume that the population is closed. Can you think of ways to include demographic variables such as births, deaths, and travel to mirror more of the complexities that surround the nature of epidemic research?

## NETLOGO FEATURES

Notice that each agent pulls from a truncated normal distribution, centered around the AVERAGE-RECOVERY-TIME set by the user. This is to account for the variation in genetic differences and the immune system functions of individuals.

Notice that R_0 calculated in this model is a numerical estimate to the analytic R_0. In the special case of one infective introduced to a wholly susceptible population (i.e., the Kermack-McKendrick assumptions), the numerical estimations of R0 are very close to the analytic values.

## RELATED MODELS

HIV, Virus and Virus on a Network are related models.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Yang, C. and Wilensky, U. (2011).  NetLogo epiDEM Basic model.  http://ccl.northwestern.edu/netlogo/models/epiDEMBasic.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2011 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2011 Cite: Yang, C. -->
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

person lefty
false
0
Circle -7500403 true true 170 5 80
Polygon -7500403 true true 165 90 180 195 150 285 165 300 195 300 210 225 225 300 255 300 270 285 240 195 255 90
Rectangle -7500403 true true 187 79 232 94
Polygon -7500403 true true 255 90 300 150 285 180 225 105
Polygon -7500403 true true 165 90 120 150 135 180 195 105

person righty
false
0
Circle -7500403 true true 50 5 80
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Rectangle -7500403 true true 67 79 112 94
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Polygon -7500403 true true 45 90 0 150 15 180 75 105

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
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
